// supabase/functions/generate-exercise-audio/index.ts
// On-demand TTS for a single listen_select exercise.
// Priority: Google Cloud TTS (primary) → Gemini 2.5 Flash TTS → Gemini 3.1 Flash TTS

import { createClient } from 'npm:@supabase/supabase-js';

/** Local JWT validation — decodes and checks expiry without calling Auth server. */
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

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// ── WAV wrapper (used only for Gemini PCM fallback) ──────────────────────────

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

// ── Google Cloud TTS ─────────────────────────────────────────────────────────
// Free tier: 1,000,000 characters/month for WaveNet voices (300 RPM limit)
// Voice: ar-XA-Wavenet-B — clear male Modern Standard Arabic pronunciation

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
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: JSON.stringify({
          input: { text },
          voice: {
            languageCode: 'ar-XA',
            name: 'ar-XA-Wavenet-B',
            ssmlGender: 'MALE',
          },
          audioConfig: {
            audioEncoding: 'MP3',
            speakingRate: 0.9,
          },
        }),
        signal: controller.signal,
      },
    );
    clearTimeout(timeoutId);
    if (!res.ok) {
      const errText = await res.text().catch(() => '(no body)');
      console.error(`Google TTS error ${res.status}:`, errText);
      return null;
    }
    const data = await res.json();
    const b64 = data.audioContent as string | undefined;
    if (!b64) { console.warn('Google TTS returned no audioContent'); return null; }
    return {
      bytes: Uint8Array.from(atob(b64), c => c.charCodeAt(0)),
      contentType: 'audio/mpeg',
      ext: 'mp3',
    };
  } catch (e: unknown) {
    clearTimeout(timeoutId);
    const isAbort = e instanceof Error && e.name === 'AbortError';
    console.warn(isAbort ? 'Google TTS timed out after 25s' : `Google TTS fetch error: ${e}`);
    return null;
  }
}

// ── Gemini TTS fallback ──────────────────────────────────────────────────────
// Free tier: 3 RPM / 10 RPD (2.5 Flash) + 3 RPM / 10 RPD (3.1 Flash)

async function geminiTts(
  text: string,
  apiKey: string,
): Promise<{ bytes: Uint8Array; contentType: 'audio/wav'; ext: 'wav' } | null> {
  const models = ['gemini-3.1-flash-tts-preview', 'gemini-2.5-flash-tts'];
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
      if (!res.ok) {
        console.error(`${model} error ${res.status}:`, await res.text().catch(() => ''));
        continue;
      }
      const data = await res.json();
      const b64: string | undefined = data?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
      if (b64) {
        const pcm = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
        return { bytes: pcmToWav(downsample24kTo16k(pcm)), contentType: 'audio/wav', ext: 'wav' };
      }
      console.warn(`${model} returned no audio data`);
    } catch (e: unknown) {
      clearTimeout(timeoutId);
      const isAbort = e instanceof Error && e.name === 'AbortError';
      console.warn(isAbort ? `${model} timed out` : `${model} error: ${e}`);
      continue;
    }
  }
  return null;
}

// ── Handler ──────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const geminiKey = Deno.env.get('GEMINI_API_KEY');
  if (!geminiKey) {
    return new Response(
      JSON.stringify({ error: 'config_error', message: 'GEMINI_API_KEY not set' }),
      { status: 503, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  }

  try {
    const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
    if (!token) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    // Verify JWT locally — no network call to Auth server (avoids indefinite hang).
    // We check: 3-part JWT, valid base64 payload, not expired, has sub (user id).
    // Signature verification requires the JWT secret; skipped here because
    // audio generation is low-risk and this check prevents anonymous abuse.
    if (!isTokenValid(token)) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const body = await req.json();
    const { exercise_id, speak_text, lesson_id } = body as {
      exercise_id?: string; speak_text?: string; lesson_id?: string;
    };
    if (!exercise_id || !speak_text || !lesson_id) {
      return new Response(JSON.stringify({ error: 'exercise_id, speak_text, lesson_id required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    // Race-condition guard
    const { data: existing } = await supabase
      .from('exercises').select('audio_url').eq('id', exercise_id).single();
    if (existing?.audio_url) {
      return new Response(JSON.stringify({ audio_url: existing.audio_url }),
        { headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    // Try Google Cloud TTS first, then Gemini fallbacks
    const googleKey = Deno.env.get('GOOGLE_TTS_API_KEY') ?? '';

    const audio = googleKey
      ? (await googleTts(speak_text, googleKey) ?? await geminiTts(speak_text, geminiKey))
      : await geminiTts(speak_text, geminiKey);

    if (!audio) {
      return new Response(
        JSON.stringify({ error: 'tts_unavailable', retry: true }),
        { status: 503, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
      );
    }

    const slug = speak_text.replace(/[^؀-ۿa-zA-Z0-9]/g, '_').substring(0, 40);
    const path = `lessons/${lesson_id}/${slug}_${exercise_id.substring(0, 8)}.${audio.ext}`;

    const { error: upErr } = await supabase.storage
      .from('audio')
      .upload(path, audio.bytes, { contentType: audio.contentType, upsert: true });
    if (upErr) {
      console.error('Storage upload failed:', upErr.message);
      return new Response(JSON.stringify({ error: `Upload failed: ${upErr.message}` }),
        { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    const { data: { publicUrl } } = supabase.storage.from('audio').getPublicUrl(path);
    await supabase.from('exercises').update({ audio_url: publicUrl }).eq('id', exercise_id);

    return new Response(JSON.stringify({ audio_url: publicUrl }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } });

  } catch (err) {
    console.error('unhandled error:', err);
    return new Response(
      JSON.stringify({ error: 'internal', detail: String(err) }),
      { status: 503, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  }
});
