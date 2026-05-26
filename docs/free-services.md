# Free Services — Ta'allam
## Everything needed to run this project at zero cost until commercial launch

## SUPABASE (primary backend) — FREE TIER
- **URL**: https://supabase.com
- **DB**: 500MB PostgreSQL (enough for ~50,000 lessons + user data)
- **Storage**: 1GB (audio files: ~50KB each = ~20,000 audio clips)
- **Auth**: 50,000 monthly active users
- **Edge Functions**: 500,000 invocations/month, 10s timeout
- **Bandwidth**: 5GB/month
- **Local dev**: `supabase start` (Docker required)
- **LIMIT WATCH**: Storage is the constraint — compress audio to <50KB mp3

## GEMINI API (content pipeline) — FREE TIER
- **Model**: gemini-3.5-flash
- **Free**: 1,500 requests/day, no credit card required
- Reads PDFs and images natively — no separate extraction step needed
- Solo admin processing 200–300 lessons total = fraction of daily limit
- **Setup**: ai.google.dev → Get API key
- **Env var**: `GEMINI_API_KEY` in Supabase Edge Function secrets (never in app)

## FLUTTER — FREE (open source)
- **Version**: 3.27+ (stable channel)
- **Platforms**: Android, iOS, Web (for admin panel + testing)
- **Install**: https://docs.flutter.dev/get-started/install
- **Required packages** (all free):
  ```yaml
  dependencies:
    # Core
    flutter_riverpod: ^2.x
    go_router: ^14.x
    
    # Database
    drift: ^2.x
    drift_flutter: ^0.x
    sqlite3_flutter_libs: ^0.x
    
    # Supabase
    supabase_flutter: ^2.x
    
    # SRS
    fsrs4dart: ^0.x           # spaced repetition algorithm
    
    # Models
    freezed_annotation: ^2.x
    json_annotation: ^4.x
    
    # Audio
    just_audio: ^0.x          # audio playback
    flutter_cache_manager: ^3.x  # cache audio files
    
    # UI
    gap: ^3.x                 # spacing utility
    
    # File upload (admin)
    file_picker: ^8.x
    
  dev_dependencies:
    freezed: ^2.x
    json_serializable: ^6.x
    build_runner: ^2.x
    drift_dev: ^2.x
    flutter_test:
      sdk: flutter
  ```

## FIREBASE FCM (push notifications) — FREE
- **Free tier**: Unlimited messages
- **Setup**: Firebase console → add Flutter app → download google-services.json
- **IMPORTANT**: Only send notifications at non-prayer times
  - Fajr: 5 min after Fajr
  - Dhuhr: avoid 12:00-12:30
  - Asr: avoid Asr time
  - Maghrib/Isha: avoid prayer times
- Adhan times API: https://aladhan.com/prayer-times-api (free, no key needed)

## POSTHOG (analytics) — FREE TIER
- **URL**: https://posthog.com
- **Free**: 1 million events/month
- **Package**: posthog_flutter (pub.dev)
- **Track**: lesson_completed, exercise_answered, streak_updated, content_viewed
- **Do NOT track**: personal data, prayer habits, exact location

## GITHUB (version control + CI) — FREE
- Private repo: free for individuals
- GitHub Actions: 2,000 minutes/month (enough for tests + builds)
- **CI workflow**: on PR → flutter test + flutter build web

## SENTRY (crash reporting) — FREE TIER
- **Free**: 5,000 errors/month
- **Package**: sentry_flutter (pub.dev)
- Only enable in production builds

## FONTS — FREE
- Arabic: Noto Naskh Arabic (Google Fonts, OFL license)
- Bangla: Hind Siliguri (Google Fonts, OFL license)
- Latin: IBM Plex Sans (IBM open source license)
- All available via `google_fonts` Flutter package

## ARABIC TTS AUDIO — FREE OPTIONS
Option A (best): Record human speaker (qualified teacher, one-time cost)
Option B: flutter_tts with Arabic voice (device TTS, no API needed)
  ```dart
  final tts = FlutterTts();
  await tts.setLanguage("ar-SA");  // Saudi Arabic
  await tts.speak(arabicText);
  ```
Option C: Cache Google TTS (free 1M chars/month via google_fonts workaround)
→ Recommended: Option A for Quranic track, Option B for conversational fallback

## ENVIRONMENT SETUP
Create `.env` (gitignored) in project root:
```
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_key  # admin only, never in app
GEMINI_API_KEY=your_key  # only in Supabase edge function secrets, never in app
```

Run app with:
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=your_local_anon_key
```
