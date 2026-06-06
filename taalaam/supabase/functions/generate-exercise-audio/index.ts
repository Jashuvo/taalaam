// supabase/functions/generate-exercise-audio/index.ts
// Called by the learner app when a listen_select exercise has no audio_url.
// Generates TTS for that one exercise, uploads to Storage, returns URL.

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

/** Try 2.5 first, fall back to 3.1 on 429. 25-second timeout per model. */
async function geminiTts(text: string, apiKey: string): Promise<Uint8Array | null> {
  const models = ['gemini-2.5-flash-preview-tts', 'gemini-3.1-flash-tts-preview'];
  for (const model of models) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 25000);
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text }] }],
            generationConfig: {
              responseModalities: ['AUDIO'],
              speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Sulafat' } } },
            },
          }),
          signal: controller.signal,
        },
      );
      clearTimeout(timeoutId);
      if (res.status === 429) { console.warn(`${model} rate-limited, trying next`); continue; }
      if (!res.ok) {
        const errText = await res.text().catch(() => '(no body)');
        console.error(`${model} error ${res.status}:`, errText);
        continue;
      }
      const data = await res.json();
      const b64: string | undefined = data?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
      if (b64) return Uint8Array.from(atob(b64), c => c.charCodeAt(0));
      console.warn(`${model} returned no audio data`);
    } catch (e: unknown) {
      clearTimeout(timeoutId);
      const isAbort = e instanceof Error && e.name === 'AbortError';
      console.warn(isAbort ? `${model} timed out after 25s` : `${model} fetch error: ${e}`);
      continue;
    }
  }
  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
    if (!token) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { error: authErr } = await supabase.auth.getUser(token);
    if (authErr) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const body = await req.json();
    const { exercise_id, speak_text, lesson_id } = body as {
      exercise_id?: string; speak_text?: string; lesson_id?: string;
    };
    if (!exercise_id || !speak_text || !lesson_id) {
      return new Response(JSON.stringify({ error: 'exercise_id, speak_text, lesson_id required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    // Race-condition guard: return existing URL if already generated
    const { data: existing } = await supabase
      .from('exercises')
      .select('audio_url')
      .eq('id', exercise_id)
      .single();
    if (existing?.audio_url) {
      return new Response(JSON.stringify({ audio_url: existing.audio_url }),
        { headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const apiKey = Deno.env.get('GEMINI_API_KEY')!;
    const pcm = await geminiTts(speak_text, apiKey);
    if (!pcm) {
      return new Response(
        JSON.stringify({ error: 'TTS unavailable (both models failed or timed out)', retry: true }),
        { status: 429, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      );
    }

    const wav = pcmToWav(pcm);
    const slug = speak_text.replace(/[^؀-ۿa-zA-Z0-9]/g, '_').substring(0, 40);
    const path = `lessons/${lesson_id}/${slug}_${exercise_id.substring(0, 8)}.wav`;

    const { error: upErr } = await supabase.storage
      .from('audio')
      .upload(path, wav, { contentType: 'audio/wav', upsert: true });
    if (upErr) {
      console.error('Storage upload failed:', upErr.message);
      return new Response(JSON.stringify({ error: `Upload failed: ${upErr.message}` }),
        { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const { data: { publicUrl } } = supabase.storage.from('audio').getPublicUrl(path);
    await supabase.from('exercises').update({ audio_url: publicUrl }).eq('id', exercise_id);

    return new Response(JSON.stringify({ audio_url: publicUrl }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } });

  } catch (e) {
    console.error('Unhandled error in generate-exercise-audio:', e);
    return new Response(JSON.stringify({ error: `Internal error: ${e}` }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }
});
