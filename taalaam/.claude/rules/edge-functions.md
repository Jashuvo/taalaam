---
paths:
  - "supabase/functions/**/*.ts"
---

# Edge Function Rules — Ta'allam

## Auth
- generate-exercise-audio uses LOCAL jwt decode (isTokenValid) — no supabase.auth.getUser() call
- All admin functions (backfill-audio, process-content, etc.) check user.email === 'jubayedsr@gmail.com'
- Deploy all functions with: supabase functions deploy <name> --no-verify-jwt

## backfill-audio — uses REST API directly (no supabase-js)
- Does NOT import npm:@supabase/supabase-js — uses fetch() against /rest/v1/ and /storage/v1/ directly
- supabase-js npm package hangs silently in Deno when looping over multiple exercises (root cause of ERR_CONNECTION_CLOSED)
- DB query: GET /rest/v1/exercises?select=...&type=eq.listen_select&audio_url=is.null
- Storage upload: POST /storage/v1/object/audio/${path} with x-upsert: true header
- Auth headers for REST: { Authorization: 'Bearer ${SERVICE_KEY}', apikey: SERVICE_KEY }

## TTS priority order (both generate-exercise-audio and backfill-audio)
1. Google Cloud TTS — ar-XA-Wavenet-B, MP3, speakingRate 0.9 (GOOGLE_TTS_API_KEY)
2. Gemini 2.5 Flash TTS — gemini-2.5-flash-tts, Sulafat voice
3. Gemini 3.1 Flash TTS — gemini-3.1-flash-tts-preview, Sulafat voice
- Always use AbortController with 10s timeout on every TTS fetch() (15s for storage uploads)
- Google returns MP3 (audio/mpeg); Gemini returns raw PCM → wrap in pcmToWav() → audio/wav
- Always wrap Deno.serve handler in try/catch to prevent ERR_CONNECTION_CLOSED

## Storage
- Bucket: 'audio' (public)
- Path pattern: lessons/${lesson_id}/tts_${exercise_id.replace(/-/g,'')}.${ext}
- ASCII-only paths — NEVER put Arabic chars in the fetch URL (storage rejects non-encoded unicode)
- Upload body must be a Blob, not a raw Uint8Array, so Content-Type is derived from the Blob type
- Headers: Authorization + apikey (both SERVICE_KEY), x-upsert: true — do NOT set Content-Type manually
- upsert: true on all uploads

## CORS headers (required on every response including errors)
```ts
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
```

## Env vars available (built-in, no need to set)
- SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
- GEMINI_API_KEY (set via: supabase secrets set GEMINI_API_KEY=...)
- GOOGLE_TTS_API_KEY (set via: supabase secrets set GOOGLE_TTS_API_KEY=...)
