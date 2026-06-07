// supabase/functions/generate-exercise-audio/index.ts
// On-demand TTS for a single listen_select exercise.
// Priority: Google Cloud TTS → Gemini 2.5 Flash TTS → Gemini 3.1 Flash TTS
// Uses Supabase REST API directly (no supabase-js) to avoid 500 crashes in Deno.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function isTokenValid(token: string): boolean {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return false;
    const pad = (s: string) => s + '='.repeat((4 - s.length % 4) % 4);
    const payload = JSON.parse(atob(pad(parts[1].replace(/-/g, '+').replace(/_/g, '/'))));
    return typeof payload.sub === 'string' && payload.exp > Date.now() / 1000;
  } catch {
    return false;
  }
}

function downsample24kTo16k(pcm24: Uint8Array): Uint8Array {
  const inSamples = pcm24.length / 2;
  const outSamples = Math.floor(inSamples * 16000 / 24000);
  const out = new Int16Array(outSamples);
  const inp = new Int16Array(pcm24.buffer, pcm24.byteOffset, inSamples);
  for (let i = 0; i < outSamples; i++) {
    const pos = i * 1.5;
    const lo = Math.floor(pos);
    const frac = pos - lo;
    out[i] = Math.round((inp[lo] ?? 0) + frac * ((inp[lo + 1] ?? 0) - (inp[lo] ?? 0)));
  }
  return new Uint8Array(out.buffer);
}

function pcmToWav(pcmBytes: Uint8Array): Uint8Array {
  const sampleRate = 16000, numCh = 1, bps = 16;
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
  const timeoutId = setTimeout(() => controller.abort(), 10000);
  try {
    const res = await fetch('https://texttospeech.googleapis.com/v1/text:synthesize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify({
        input: { text },
        voice: { languageCode: 'ar-XA', name: 'ar-XA-Wavenet-B', ssmlGender: 'MALE' },
        audioConfig: { audioEncoding: 'MP3', speakingRate: 0.9 },
      }),
      signal: controller.signal,
    });
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
  const models = ['gemini-2.5-flash-tts', 'gemini-3.1-flash-tts-preview'];
  for (const model of models) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);
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
        return { bytes: pcmToWav(downsample24kTo16k(pcm)), contentType: 'audio/wav', ext: 'wav' };
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

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
  const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const GEMINI_KEY   = Deno.env.get('GEMINI_API_KEY');
  const GOOGLE_KEY   = Deno.env.get('GOOGLE_TTS_API_KEY') ?? '';

  if (!GEMINI_KEY) {
    return new Response(JSON.stringify({ error: 'GEMINI_API_KEY not set' }),
      { status: 503, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }

  const dbHeaders = {
    'Authorization': `Bearer ${SERVICE_KEY}`,
    'apikey': SERVICE_KEY,
    'Content-Type': 'application/json',
  };

  try {
    const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
    if (!token || !isTokenValid(token)) {
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
    const checkRes = await fetch(
      `${SUPABASE_URL}/rest/v1/exercises?id=eq.${encodeURIComponent(exercise_id)}&select=audio_url`,
      { headers: dbHeaders },
    ).catch(() => null);
    if (checkRes?.ok) {
      const rows = await checkRes.json().catch(() => []);
      const existing = rows[0]?.audio_url as string | undefined;
      if (existing) {
        return new Response(JSON.stringify({ audio_url: existing }),
          { headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }
    }

    // TTS
    const audio = GOOGLE_KEY
      ? (await googleTts(speak_text, GOOGLE_KEY) ?? await geminiTts(speak_text, GEMINI_KEY))
      : await geminiTts(speak_text, GEMINI_KEY);

    if (!audio) {
      return new Response(JSON.stringify({ error: 'tts_unavailable', retry: true }),
        { status: 503, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    // ASCII-only path: no Arabic chars in URL to avoid storage rejections
    const path = `lessons/${lesson_id}/tts_${exercise_id.replace(/-/g, '')}.${audio.ext}`;
    const uploadUrl = `${SUPABASE_URL}/storage/v1/object/audio/${path}`;

    // Upload to Supabase Storage via REST API (Blob body so Content-Type is set correctly)
    const uploadCtrl = new AbortController();
    const uploadTimer = setTimeout(() => uploadCtrl.abort(), 15000);
    let uploadOk = false;
    try {
      const blob = new Blob([audio.bytes], { type: audio.contentType });
      const upRes = await fetch(uploadUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'apikey': SERVICE_KEY,
          'x-upsert': 'true',
        },
        body: blob,
        signal: uploadCtrl.signal,
      });
      clearTimeout(uploadTimer);
      if (!upRes.ok) {
        const body = await upRes.text().catch(() => '');
        console.error(`Storage upload failed ${upRes.status}:`, body);
      } else {
        uploadOk = true;
      }
    } catch (upErr) {
      clearTimeout(uploadTimer);
      console.error('Storage upload error:', upErr);
    }

    if (!uploadOk) {
      return new Response(JSON.stringify({ error: 'upload_failed' }),
        { status: 503, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/audio/${path}`;

    // Update exercise record
    await fetch(
      `${SUPABASE_URL}/rest/v1/exercises?id=eq.${encodeURIComponent(exercise_id)}`,
      {
        method: 'PATCH',
        headers: { ...dbHeaders, 'Prefer': 'return=minimal' },
        body: JSON.stringify({ audio_url: publicUrl }),
      },
    ).catch(e => console.error('DB update error:', e));

    return new Response(JSON.stringify({ audio_url: publicUrl }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } });

  } catch (err) {
    console.error('unhandled error:', err);
    return new Response(JSON.stringify({ error: 'internal', detail: String(err) }),
      { status: 503, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  }
});
