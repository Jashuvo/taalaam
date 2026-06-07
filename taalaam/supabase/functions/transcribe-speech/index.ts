// supabase/functions/transcribe-speech/index.ts
// Receives audio bytes (base64) + expected Arabic text.
// Sends audio to Gemini for transcription, compares to expected, returns result.
// Called by the speak_arabic exercise widget in the learner app.

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/** Strip harakat/diacritics and normalize alef variants for loose matching */
function normalizeAr(text: string): string {
  return text
    .replace(/[ً-ٟؐ-ؚٰ]/g, '') // harakat + superscript alef
    .replace(/ـ/g, '')                               // tatweel
    .replace(/[أإآٱ]/g, 'ا')                             // alef variants → plain alef
    .replace(/ة/g, 'ه')                                  // ta marbuta → ha (forgiving)
    .replace(/ى/g, 'ي')                                  // alef maqsura → ya
    .replace(/\s+/g, ' ')
    .trim();
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  // Any authenticated learner may call this endpoint
  const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
  if (!token) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }

  // Local JWT validation — no Auth server call needed
  const isValid = (() => {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return false;
      const pad = (s: string) => s + '='.repeat((4 - s.length % 4) % 4);
      const p = JSON.parse(atob(pad(parts[1].replace(/-/g, '+').replace(/_/g, '/'))));
      return typeof p.sub === 'string' && p.exp > Date.now() / 1000;
    } catch { return false; }
  })();
  if (!isValid) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }

  try {
    const { audio_base64, mime_type, expected_ar } = await req.json();

    if (!audio_base64 || !expected_ar) {
      return new Response(
        JSON.stringify({ error: 'audio_base64 and expected_ar are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    const normalizedExpected = normalizeAr(expected_ar);

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const result = await model.generateContent({
      contents: [{
        role: 'user',
        parts: [
          {
            inlineData: {
              mimeType: mime_type ?? 'audio/webm',
              data: audio_base64,
            },
          },
          {
            text: `A student is practicing Arabic pronunciation. They were asked to say: "${normalizedExpected}"

Listen to the audio and return ONLY a JSON object with no markdown fences:
{"heard": "Arabic text without harakat", "clear": true}

If the audio is silent, too quiet, or contains no recognisable Arabic speech:
{"heard": "", "clear": false}`,
          },
        ],
      }],
    });

    let txt = result.response.text().trim();
    if (txt.startsWith('```')) {
      txt = txt.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
    }

    let heard = '';
    let clear = false;
    try {
      const parsed = JSON.parse(txt);
      heard = ((parsed.heard as string) ?? '').trim();
      clear = parsed.clear === true;
    } catch {
      // Fallback: extract any Arabic characters from raw response
      heard = txt.replace(/[^؀-ۿ\s]/g, '').trim();
      clear = heard.length > 0;
    }

    const normalizedHeard = normalizeAr(heard);
    const correct =
      clear &&
      normalizedHeard.length > 0 &&
      normalizedHeard === normalizedExpected;

    return new Response(
      JSON.stringify({ correct, transcription: heard, clear }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: msg }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
});
