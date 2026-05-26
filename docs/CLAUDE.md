# Ta'allam (تعلَّم) — Sahih Arabic Learning App
Solo project. Bangla-first. Flutter + Supabase. Free tier only until commercial launch.

## COMMANDS (use these exactly)
```bash
# Dev — mobile/web test
flutter run -d chrome -t lib/main.dart --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Admin panel (same codebase, different entry)
flutter run -d chrome -t lib/main_admin.dart --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Code generation (after model changes)
dart run build_runner build --delete-conflicting-outputs

# Tests
flutter test
flutter test test/widget/ --reporter=expanded

# Supabase local
supabase start && supabase db reset

# Deploy edge function
supabase functions deploy <function-name> --no-verify-jwt
```

## ARCHITECTURE DECISIONS — NEVER CHANGE WITHOUT ASKING
- State: **Riverpod** (flutter_riverpod + hooks_riverpod). No Provider, no Bloc.
- Routing: **go_router**. All routes in `lib/core/router/app_router.dart`.
- Local DB: **Drift** (SQLite). All tables in `lib/data/local/database.dart`.
- Remote: **Supabase** client only. No REST calls with http package.
- Models: **Freezed** with json_serializable. Immutable always.
- Arabic text: Always use `TextDirection.rtl` wrapper. Never hardcode direction.
- Two app flavors: `main.dart` (learner) and `main_admin.dart` (content manager).
- Offline-first: Drift is source of truth. Supabase syncs in background.

## FOLDER STRUCTURE (feature-first)
```
lib/
  core/           # theme, router, constants, utils
  features/
    auth/         # login, onboarding
    home/         # dashboard, lesson path map
    lesson/       # exercise engine (6 types)
    srs/          # spaced repetition (FSRS)
    track_conv/   # conversational track
    track_quran/  # quranic + tafsir track
    admin/        # content upload + review panel
  data/
    local/        # Drift database + DAOs
    remote/       # Supabase queries
    models/       # Freezed models (shared)
  shared/
    widgets/      # reusable UI components
    services/     # audio, tts, notifications
supabase/
  functions/      # Deno edge functions
  migrations/     # SQL migrations (numbered)
```

## CRITICAL RULES
- Every feature folder has: `data/`, `domain/`, `presentation/` sub-folders.
- No business logic in widgets. Widgets call providers only.
- All Supabase queries in `data/remote/`. Providers call repositories.
- Arabic text rendering: always test with sample text `هُوَ أُسْتَاذٌ`.
- Use `const` constructors everywhere possible.
- New screens must have a corresponding widget test before PR.

## DOCS (load these with @ when working on that area)
- @docs/architecture.md — full system design + data flow
- @docs/schema.md — database schema (Drift + Supabase)
- @docs/features.md — feature checklist with [ ] boxes
- @docs/content-pipeline.md — how source PDFs become lessons
- @docs/conventions.md — naming, style, Arabic handling rules
- @docs/free-services.md — all free services + their limits
