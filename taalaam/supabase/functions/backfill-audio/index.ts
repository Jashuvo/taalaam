// supabase/functions/backfill-audio/index.ts
// Admin-only: generates Gemini TTS audio for all listen_select exercises
// that currently have audio_url = null.

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
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

  // Admin check
  const { data: { user }, error: authErr } = await supabase.auth.getUser(token);
  if (authErr || user?.email !== 'jubayedsr@gmail.com') {
    return new Response(JSON.stringify({ error: 'Admin only' }),
      { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  // Fetch all listen_select exercises with no audio
  const { data: exercises, error: fetchErr } = await supabase
    .from('exercises')
    .select('id, lesson_id, correct_answer')
    .eq('type', 'listen_select')
    .is('audio_url', null);

  if (fetchErr) {
    return new Response(JSON.stringify({ error: fetchErr.message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
  let done = 0, failed = 0;
  const succeededWords: string[] = [];

  // Process in batches of 5 to avoid rate limits
  const batchSize = 5;
  for (let i = 0; i < (exercises ?? []).length; i += batchSize) {
    const batch = (exercises ?? []).slice(i, i + batchSize);
    await Promise.all(batch.map(async (ex) => {
      const speakText = ex.correct_answer?.speak_text as string | undefined;
      if (!speakText) { failed++; return; }

      try {
        const ttsModel = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
        const result = await (ttsModel as any).generateContent({
          contents: [{ role: 'user', parts: [{ text: speakText }] }],
          generationConfig: {
            responseModalities: ['AUDIO'],
            speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Sulafah' } } },
          },
        });

        const audioB64: string | undefined =
          result?.response?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
        if (!audioB64) { failed++; return; }

        const pcm = Uint8Array.from(atob(audioB64), c => c.charCodeAt(0));
        const wav = pcmToWav(pcm);
        const slug = speakText.replace(/[^؀-ۿa-zA-Z0-9]/g, '_').substring(0, 40);
        const path = `lessons/${ex.lesson_id}/${slug}_${ex.id.substring(0, 8)}.wav`;

        const { error: upErr } = await supabase.storage
          .from('audio')
          .upload(path, wav, { contentType: 'audio/wav', upsert: true });
        if (upErr) { failed++; return; }

        const { data: { publicUrl } } = supabase.storage.from('audio').getPublicUrl(path);
        await supabase.from('exercises').update({ audio_url: publicUrl }).eq('id', ex.id);
        done++;
        succeededWords.push(speakText);
      } catch {
        failed++;
      }
    }));
  }

  return new Response(
    JSON.stringify({ total: (exercises ?? []).length, done, failed, words: succeededWords }),
    { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
  );
});
