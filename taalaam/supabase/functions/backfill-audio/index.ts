// supabase/functions/backfill-audio/index.ts
// Admin-only: generate TTS audio for all (or one lesson's) listen_select exercises.
// Priority: Google Cloud TTS → Gemini 2.5 Flash TTS → Gemini 3.1 Flash TTS
// Optional body: { lesson_id: "uuid" } to restrict to one lesson.

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

async function googleTts(
  text: string,
  apiKey: string,
): Promise<{ bytes: Uint8Array; contentType: 'audio/mpeg'; ext: 'mp3' } | null> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 25000);
  try {
    const res = await fetch(
      'https://texttospeech.googleapis.com/v1/text:synthesize',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
        body: JSON.stringify({
          input: { text },
          voice: { languageCode: 'ar-XA', name: 'ar-XA-Wavenet-B', ssmlGender: 'MALE' },
          audioConfig: { audioEncoding: 'MP3', speakingRate: 0.9 },
        }),
        signal: controller.signal,
      },
    );
    clearTimeout(timeoutId);
    if (!res.ok) {
      console.error(`Google TTS ${res.status}:`, await res.text().catch(() => ''));
      return null;
    }
    const data = await res.json();
    const b64 = data.audioContent as string | undefined;
    if (!b64) return null;
    return { bytes: Uint8Array.from(atob(b64), c => c.charCodeAt(0)), contentType: 'audio/mpeg', ext: 'mp3' };
  } catch (e: unknown) {
    clearTimeout(timeoutId);
    console.warn(e instanceof Error && e.name === 'AbortError' ? 'Google TTS timeout' : `Google TTS: ${e}`);
    return null;
  }
}

async function geminiTts(
  text: string,
  apiKey: string,
): Promise<{ bytes: Uint8Array; contentType: 'audio/wav'; ext: 'wav' } | null> {
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
      if (res.status === 429) { console.warn(`${model} rate-limited`); continue; }
      if (!res.ok) { console.error(`${model} ${res.status}`); continue; }
      const data = await res.json();
      const b64: string | undefined = data?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
      if (b64) {
        const pcm = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
        return { bytes: pcmToWav(pcm), contentType: 'audio/wav', ext: 'wav' };
      }
    } catch (e: unknown) {
      clearTimeout(timeoutId);
      console.warn(e instanceof Error && e.name === 'AbortError' ? `${model} timeout` : `${model}: ${e}`);
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

    const { data: { user }, error: authErr } = await supabase.auth.getUser(token);
    if (authErr || user?.email !== 'jubayedsr@gmail.com') {
      return new Response(JSON.stringify({ error: 'Admin only' }),
        { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const body = await req.json().catch(() => ({})) as { lesson_id?: string };
    const targetLessonId = body.lesson_id ?? null;

    let query = supabase
      .from('exercises')
      .select('id, lesson_id, correct_answer')
      .eq('type', 'listen_select')
      .is('audio_url', null);
    if (targetLessonId) {
      query = query.eq('lesson_id', targetLessonId) as typeof query;
    }

    const { data: exercises, error: fetchErr } = await query;
    if (fetchErr) {
      return new Response(JSON.stringify({ error: fetchErr.message }),
        { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const googleKey = Deno.env.get('GOOGLE_TTS_API_KEY') ?? '';
    const geminiKey = Deno.env.get('GEMINI_API_KEY')!;

    let done = 0, failed = 0;
    const succeededWords: string[] = [];
    const failedWords: string[] = [];

    for (const ex of (exercises ?? [])) {
      const speakText = ex.correct_answer?.speak_text as string | undefined;
      if (!speakText) { failed++; failedWords.push('(no speak_text)'); continue; }

      try {
        const audio = googleKey
          ? (await googleTts(speakText, googleKey) ?? await geminiTts(speakText, geminiKey))
          : await geminiTts(speakText, geminiKey);

        if (!audio) { failed++; failedWords.push(speakText); continue; }

        const slug = speakText.replace(/[^؀-ۿa-zA-Z0-9]/g, '_').substring(0, 40);
        const path = `lessons/${ex.lesson_id}/${slug}_${ex.id.substring(0, 8)}.${audio.ext}`;

        const { error: upErr } = await supabase.storage
          .from('audio')
          .upload(path, audio.bytes, { contentType: audio.contentType, upsert: true });
        if (upErr) { failed++; failedWords.push(speakText); continue; }

        const { data: { publicUrl } } = supabase.storage.from('audio').getPublicUrl(path);
        await supabase.from('exercises').update({ audio_url: publicUrl }).eq('id', ex.id);
        done++;
        succeededWords.push(speakText);
      } catch (e) {
        console.error('backfill error for', speakText, e);
        failed++;
        failedWords.push(speakText);
      }
    }

    return new Response(
      JSON.stringify({ total: (exercises ?? []).length, done, failed, words: succeededWords, failedWords }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );

  } catch (e) {
    console.error('Unhandled error:', e);
    return new Response(JSON.stringify({ error: `Internal error: ${e}` }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }
});
