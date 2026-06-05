// supabase/functions/generate-exercise-audio/index.ts
// Called by the learner app when a listen_select exercise has no audio_url.
// Generates TTS for that one exercise, uploads to Storage, returns URL.
// Gemini TTS free tier: 3 RPM — single on-demand calls stay well within that.

import { createClient } from 'npm:@supabase/supabase-js';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function pcmToWav(pcmBytes: Uint8Array): Uint8Array {
  const sampleRate = 24000, numCh = 1, bps = 16;
  const byteRate = sampleRate * numCh * bps / 8;
  const buf = new ArrayBuffer(44 + pcmBytes.length);
  const v = new DataView(buf);
  const enc = (s: string, off: number) =>
    [...s].forEach((c, i) => v.setUint8(off + i, c.charCodeAt(0)));
  enc('RIFF', 0); v.setUint32(4, 36 + pcmBytes.length, true); enc('WAVE', 8);
  enc('fmt ', 12); v.setUint32(16, 16, true); v.setUint16(20, 1, true);
  v.setUint16(22, numCh, true); v.setUint32(24, sampleRate, true);
  v.setUint32(28, byteRate, true); v.setUint16(32, numCh * bps / 8, true);
  v.setUint16(34, bps, true); enc('data', 36); v.setUint32(40, pcmBytes.length, true);
  new Uint8Array(buf).set(pcmBytes, 44);
  return new Uint8Array(buf);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
  if (!token) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Any authenticated learner can trigger on-demand audio generation
  const { error: authErr } = await supabase.auth.getUser(token);
  if (authErr) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  const { exercise_id, speak_text, lesson_id } = await req.json();
  if (!exercise_id || !speak_text || !lesson_id) {
    return new Response(JSON.stringify({ error: 'exercise_id, speak_text, lesson_id required' }),
      { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  // Check if audio already exists (race condition guard)
  const { data: existing } = await supabase
    .from('exercises')
    .select('audio_url')
    .eq('id', exercise_id)
    .single();
  if (existing?.audio_url) {
    return new Response(JSON.stringify({ audio_url: existing.audio_url }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  // Generate TTS via Gemini
  const apiKey = Deno.env.get('GEMINI_API_KEY')!;
  const ttsRes = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: speak_text }] }],
        generationConfig: {
          responseModalities: ['AUDIO'],
          speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Sulafat' } } },
        },
      }),
    },
  );

  if (!ttsRes.ok) {
    const err = await ttsRes.json();
    // Return 429 so Flutter knows to retry later
    return new Response(JSON.stringify({ error: err?.error?.message ?? 'TTS failed', retry: true }),
      { status: ttsRes.status, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  const ttsData = await ttsRes.json();
  const audioB64: string | undefined =
    ttsData?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
  if (!audioB64) {
    return new Response(JSON.stringify({ error: 'No audio in response' }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  const pcm = Uint8Array.from(atob(audioB64), c => c.charCodeAt(0));
  const wav = pcmToWav(pcm);
  const slug = speak_text.replace(/[^؀-ۿa-zA-Z0-9]/g, '_').substring(0, 40);
  const path = `lessons/${lesson_id}/${slug}_${exercise_id.substring(0, 8)}.wav`;

  await supabase.storage.from('audio').upload(path, wav, { contentType: 'audio/wav', upsert: true });
  const { data: { publicUrl } } = supabase.storage.from('audio').getPublicUrl(path);

  await supabase.from('exercises').update({ audio_url: publicUrl }).eq('id', exercise_id);

  return new Response(JSON.stringify({ audio_url: publicUrl }),
    { headers: { 'Content-Type': 'application/json', ...corsHeaders } });
});
