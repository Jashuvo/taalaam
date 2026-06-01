# Ta'allam (تعلَّم) — Sahih Arabic Learning App
Solo project. Bangla-first. Flutter + Supabase. Free tier only.

## COMMANDS
```bash
flutter run -d chrome -t lib/main.dart --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
flutter run -d chrome -t lib/main_admin.dart --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
dart run build_runner build --delete-conflicting-outputs
supabase functions deploy <name> --no-verify-jwt
supabase db push --linked
```

## ARCHITECTURE — NEVER CHANGE WITHOUT ASKING
- State: **Riverpod** only. No Provider, no Bloc.
- Routing: **go_router** → `lib/core/router/app_router.dart`
- Local DB: **Drift** (SQLite) → `lib/data/local/database.dart`
- Remote: **Supabase** client only. No raw http calls.
- Models: **Freezed** + json_serializable. Immutable always.
- Two flavors: `main.dart` (learner) · `main_admin.dart` (admin)
- Offline-first: Drift is source of truth. Supabase syncs in background.

## FOLDER STRUCTURE
```
lib/
  core/theme/app_theme.dart   ← AppColors, AppSpacing, AppRadius, AppText
  features/{feature}/
    data/                     ← repository + local/remote sources
    domain/                   ← Freezed models
    presentation/             ← screens, providers, widgets/
  data/local/tables/          ← Drift table definitions
  shared/services/sync_service.dart
supabase/migrations/          ← numbered SQL files
```

## CRITICAL RULES
- No business logic in widgets. Widgets call providers only.
- Arabic text: always wrap in `Directionality(textDirection: TextDirection.rtl)`.
- Font: `NotoNaskhArabic`, fontSize ≥ 20, height 1.8.
- Colors/spacing: use `AppColors.*`, `AppSpacing.*`, `AppRadius.*` — never hardcode hex.
- `const` constructors everywhere possible.

## DATA SYNC PATTERN
- **Content** (tracks/units/lessons/vocab): Supabase → Drift via `SyncService`
- **User data** (progress/streaks/SRS/bookmarks): write Drift first, push Supabase fire-and-forget
- **On login**: `SyncService.restoreUserData(userId)` pulls all user data back to Drift

## EXERCISE TYPES
`multipleChoice` · `tapToBuild` · `fillInBlank` · `dragDrop` · `wordScramble` · `trueFalse`
All go through `ExerciseEngine` → individual widget per type.

## NEVER DO
- No animated living creature mascot
- No background music / autoplay audio
- No subscription mechanics or in-app currency
- No ads on learner screens
