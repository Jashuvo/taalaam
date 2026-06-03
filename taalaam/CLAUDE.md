# Ta'allam (تعلَّم) — Bangla-first Arabic Learning App
Solo project. Flutter 3.44 + Supabase. Free tier only. Admin: jubayedsr@gmail.com

## COMMANDS
```bash
flutter run -d chrome -t lib/main.dart --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
flutter run -d chrome -t lib/main_admin.dart --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
dart run build_runner build --delete-conflicting-outputs   # after Drift schema changes
supabase functions deploy <name> --no-verify-jwt
supabase db push --linked
```

## ARCHITECTURE
- State: **Riverpod** only (no Provider, no Bloc)
- Routing: **go_router** → `lib/core/router/app_router.dart`
- Local DB: **Drift** schema v4 → `lib/data/local/database.dart`
- Remote: **Supabase** client only (no raw http)
- Models: **Freezed** + json_serializable (immutable, snake_case JSON via .g.dart)
- Two entry points: `main.dart` (learner) · `main_admin.dart` (admin)
- Offline-first: Drift is source of truth; Supabase syncs in background

## KEY PATHS
```
lib/
  core/theme/app_theme.dart          ← AppColors, AppSpacing, AppRadius, AppText
  core/constants/app_constants.dart  ← heartsPerLesson=5, xpPerExercise=5
  core/router/app_router.dart
  data/local/database.dart           ← schemaVersion=4, migrations v1-v4
  data/local/tables/                 ← Drift table definitions
  features/home/presentation/        ← home_page, home_provider, track_detail_page
  features/lesson/presentation/      ← lesson_screen, exam_screen, lesson_provider
  features/lesson/presentation/widgets/  ← exercise_engine + per-type widgets
  features/srs/presentation/         ← memorize_screen, review_screen, srs_provider
  shared/services/progression_service.dart  ← SRS XP/streak/hearts awards
  shared/services/sync_service.dart
supabase/functions/                  ← Deno edge functions
supabase/migrations/                 ← 0001-0013 SQL
```

## DRIFT SCHEMA (v4) — key tables
| Table | Notable columns |
|---|---|
| `tracks` | id, slug, title_bn, title_ar, sort_order, status |
| `units` | id, track_id, title_bn, title_ar, sort_order, status |
| `lessons` | id, unit_id, title_bn, level, sort_order, status, **is_exam**, **gem_reward**, xp_reward |
| `exercises` | id, lesson_id, type, sort_order, prompt_bn, prompt_ar, correct_answer (JSON), distractors (JSON), grammar_note_bn, difficulty |
| `vocabulary` | id, lesson_id, arabic, transliteration, meaning_bn, meaning_en, word_type, gender, audio_url, frequency_rank, **context_snippet_ar**, **context_snippet_bn** |
| `srs_cards` | id, user_id, vocabulary_id, due_date, stability, difficulty, reps, lapses, state, last_review |
| `streaks` | user_id (PK), current_streak, longest_streak, last_activity_date, total_xp, **hearts** (1-5), freeze_count |
| `user_progress` | id, user_id, lesson_id, completed_at, xp_earned, accuracy_pct, hearts_remaining |
| `exam_questions` | id, unit_id, type, prompt_bn, prompt_ar, correct_answer (JSON), distractors (JSON), difficulty |

**Bold = added in recent migrations.** Schema migrations: v1 base → v2 freeze+bookmarks → v3 is_exam+gem_reward → v4 hearts+context_snippets.

## EDGE FUNCTIONS (all admin-guarded via JWT email check)
| Function | Trigger | What it does |
|---|---|---|
| `process-content` | Admin upload | Gemini reads PDF/TXT/image → inserts unit+lessons+exercises+vocabulary |
| `generate-exam` | Admin button | Gemini generates 30-question pool → `exam_questions` table |
| `regenerate-exercise` | Admin button | Regenerates one exercise with Gemini |
| `regenerate-vocab` | Admin button | Extracts vocabulary from existing exercises for a lesson |
| `sort-lessons` | Admin button | Gemini sorts lessons within a unit pedagogically |
| `sort-units` | Admin button | Gemini sorts+deduplicates units within a track |
| `conversation` | Learner | Conversational AI (no admin guard — learner-facing) |

## EXERCISE TYPES & WIDGET MAP
`multipleChoice` → `ExerciseMultipleChoice`  
`tapToBuild` → `ExerciseTapToBuild` — reads `correctAnswer.words`, `correctAnswer.distractor_words`  
`fillInBlank` → `ExerciseFillBlank` — reads `correctAnswer.sentence` (with `___`), `correctAnswer.answer`, `distractors.options`  
`trueFalse` → `ExerciseTrueFalse` — reads `correctAnswer.is_true`, `correctAnswer.statement_ar`, `correctAnswer.statement_bn`  
`dragDrop` → `ExerciseDragDrop`  
`wordScramble` → `ExerciseWordScramble`

**Exam screen** maps `exam_questions` DB format → widget format in `_examQuestionsProvider` (exam_screen.dart). Key remaps: `words_ar→words`, `prompt_ar→sentence` (fill_in_blank), `prompt_ar/bn→statement_ar/bn` (true_false).

## SRS / GAMIFICATION
- Algorithm: **FSRS-4.5** (`lib/features/srs/data/fsrs_algorithm.dart`)
- Cards created on lesson complete from `vocabulary` rows for that lesson
- **MemorizeScreen**: low stability (`< 2.0`) or `reps < 3` → Word Bank mode (tap chips); else keyboard
- **ReviewScreen**: standard flashcard flip with 4-star rating
- On batch complete: `ProgressionService.awardSrsSession()` → +10 XP, streak update, +1 heart (capped at 5)
- Context snippets (`vocabulary.context_snippet_ar/bn`) shown as gold block after card reveal

## SECURITY MODEL
- Admin identified by `email = 'jubayedsr@gmail.com'` in RLS policies and edge function JWT checks
- All 6 admin edge functions call `checkAdmin(req)` → verifies JWT via Supabase Auth before any DB writes
- RLS enabled on all tables; `exam_questions`, `vocabulary`, `exercises` have admin ALL + public SELECT-published policies
- Anon key in Flutter build is acceptable (RLS limits what it can access)
- **Known limitation**: single hardcoded admin email — no role table. Acceptable for solo project.

## DATA SYNC PATTERN
- **Content** (tracks/units/lessons/vocab): Supabase → Drift via `SyncService`
- **User data** (progress/streaks/SRS): write Drift first, push Supabase fire-and-forget
- On login: `SyncService.restoreUserData(userId)` pulls all user data to Drift

## CRITICAL RULES
- Arabic text: always `Directionality(textDirection: TextDirection.rtl, ...)`
- Font: `NotoNaskhArabic`, fontSize ≥ 20, height 1.8
- Colors/spacing: `AppColors.*`, `AppSpacing.*`, `AppRadius.*` — never hardcode hex
- Riverpod: NEVER create `StreamProvider`/`FutureProvider` inside `build()` — always top-level or `initState`
- `ExerciseModel.fromJson` uses **camelCase** JSON keys (no fieldRename) — always map snake_case DB columns manually
- After Drift table changes: run `dart run build_runner build --delete-conflicting-outputs` AND bump `schemaVersion` AND add `onUpgrade` migration

## NEVER DO
- No animated living creature mascot
- No background music / autoplay audio
- No subscription mechanics
- No ads on learner screens
- No `--no-verify-jwt` removal without updating `checkAdmin` guard first
