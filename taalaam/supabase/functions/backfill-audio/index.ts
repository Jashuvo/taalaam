// supabase/functions/backfill-audio/index.ts
// Admin-only: generates Gemini TTS audio for all listen_select exercises
// that currently have audio_url = null.

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

/** Try 2.5 first, fall back to 3.1 on 429. Returns raw PCM bytes or null. */
async function geminiTts(speakText: string, apiKey: string): Promise<Uint8Array | null> {
  const models = ['gemini-2.5-flash-preview-tts', 'gemini-3.1-flash-tts-preview'];
  for (const model of models) {
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: speakText }] }],
            generationConfig: {
              responseModalities: ['AUDIO'],
              speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Sulafat' } } },
            },
          }),
        },
      );
      if (res.status === 429) { console.warn(`${model} rate-limited, trying next`); continue; }
      if (!res.ok) { console.error(model, res.status, await res.text()); continue; }
      const data = await res.json();
      const b64: string | undefined = data?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
      if (b64) return Uint8Array.from(atob(b64), c => c.charCodeAt(0));
    } catch (e) { console.error(model, e); continue; }
  }
  return null;
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

  const { data: { user }, error: authErr } = await supabase.auth.getUser(token);
  if (authErr || user?.email !== 'jubayedsr@gmail.com') {
    return new Response(JSON.stringify({ error: 'Admin only' }),
      { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  const { data: exercises, error: fetchErr } = await supabase
    .from('exercises')
    .select('id, lesson_id, correct_answer')
    .eq('type', 'listen_select')
    .is('audio_url', null);

  if (fetchErr) {
    return new Response(JSON.stringify({ error: fetchErr.message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  const apiKey = Deno.env.get('GEMINI_API_KEY')!;
  let done = 0, failed = 0;
  const succeededWords: string[] = [];
  const failedWords: string[] = [];

  // Batches of 5 to stay within Gemini rate limits
  const batchSize = 5;
  for (let i = 0; i < (exercises ?? []).length; i += batchSize) {
    const batch = (exercises ?? []).slice(i, i + batchSize);
    await Promise.all(batch.map(async (ex) => {
      const speakText = ex.correct_answer?.speak_text as string | undefined;
      if (!speakText) { failed++; failedWords.push('(no speak_text)'); return; }

      try {
        const pcm = await geminiTts(speakText, apiKey);
        if (!pcm) { failed++; failedWords.push(speakText); return; }

        const wav = pcmToWav(pcm);
        const slug = speakText.replace(/[^؀-ۿa-zA-Z0-9]/g, '_').substring(0, 40);
        const path = `lessons/${ex.lesson_id}/${slug}_${ex.id.substring(0, 8)}.wav`;

        const { error: upErr } = await supabase.storage
          .from('audio')
          .upload(path, wav, { contentType: 'audio/wav', upsert: true });
        if (upErr) { failed++; failedWords.push(speakText); return; }

        const { data: { publicUrl } } = supabase.storage.from('audio').getPublicUrl(path);
        await supabase.from('exercises').update({ audio_url: publicUrl }).eq('id', ex.id);
        done++;
        succeededWords.push(speakText);
      } catch (e) {
        console.error('backfill error for', speakText, e);
        failed++;
        failedWords.push(speakText);
      }
    }));
  }

  return new Response(
    JSON.stringify({
      total: (exercises ?? []).length,
      done,
      failed,
      words: succeededWords,
      failedWords,
    }),
    { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
  );
});
