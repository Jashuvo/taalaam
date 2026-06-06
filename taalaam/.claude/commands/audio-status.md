Check audio generation status for Ta'allam exercises.

Steps:
1. Query Supabase to count listen_select exercises with and without audio_url:
   - Run via Supabase client or check admin upload page backfill button result
2. Check the Gemini TTS quota: quota is visible at aistudio.google.com under "API usage"
   - Gemini 2.5 Flash TTS: 10 RPD limit
   - Gemini 3.1 Flash TTS: 10 RPD limit
3. If GOOGLE_TTS_API_KEY is set, Google Cloud TTS has 1M chars/month — check usage at console.cloud.google.com
4. Report:
   - Total listen_select exercises
   - How many have audio_url set
   - How many are missing audio
   - Which TTS provider is active (Google if GOOGLE_TTS_API_KEY set, else Gemini)
5. If missing audio > 0, suggest running the backfill from admin upload page

$ARGUMENTS (optional lesson_id to check only that lesson)
