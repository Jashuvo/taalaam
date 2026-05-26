# Database Schema — Ta'allam

## Supabase (PostgreSQL) — Source of Truth for Content

```sql
-- CURRICULUM STRUCTURE
create table tracks (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,          -- 'conversational' | 'quranic'
  name_ar text not null,
  name_bn text not null,
  name_en text not null,
  description_bn text,
  sort_order int default 0
);

create table units (
  id uuid primary key default gen_random_uuid(),
  track_id uuid references tracks(id),
  slug text not null,
  title_ar text,
  title_bn text not null,
  title_en text,
  description_bn text,
  sort_order int not null,
  status text default 'draft',        -- 'draft' | 'published'
  source_material_id uuid             -- ref to raw upload
);

create table lessons (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid references units(id),
  title_bn text not null,
  title_ar text,
  sort_order int not null,
  xp_reward int default 10,
  status text default 'draft',
  level text default 'beginner'       -- 'beginner'|'intermediate'|'advanced'
);

create table exercises (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id),
  type text not null,                 -- see ExerciseType enum
  sort_order int not null,
  prompt_ar text,
  prompt_bn text,
  prompt_en text,
  correct_answer jsonb not null,      -- flexible per exercise type
  distractors jsonb,                  -- wrong options for MCQ/drag-drop
  audio_url text,                     -- Supabase Storage URL
  grammar_note_bn text,               -- explanation shown after answer
  grammar_note_en text,
  difficulty int default 1            -- 1-5
);

-- VOCABULARY (separate from exercises, feeds SRS)
create table vocabulary (
  id uuid primary key default gen_random_uuid(),
  arabic text not null,
  transliteration text,
  meaning_bn text not null,
  meaning_en text,
  root_letters text,                  -- e.g. 'ذ-ه-ب' for ذهب
  word_type text,                     -- 'noun'|'verb'|'particle'|'adjective'
  gender text,                        -- 'masculine'|'feminine'|null
  audio_url text,
  lesson_id uuid references lessons(id),
  frequency_rank int                  -- Quranic frequency rank
);

-- CONTENT MANAGEMENT (admin upload pipeline)
create table source_materials (
  id uuid primary key default gen_random_uuid(),
  filename text not null,
  storage_path text not null,         -- Supabase Storage path
  file_type text,                     -- 'pdf'|'text'|'image'
  processing_status text default 'pending',  -- 'pending'|'processing'|'done'|'error'
  raw_extracted_text text,            -- text extracted from PDF
  ai_output jsonb,                    -- raw Claude response
  created_at timestamptz default now(),
  processed_at timestamptz,
  notes text                          -- admin notes
);

-- USER PROGRESS (synced from device)
create table user_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  lesson_id uuid references lessons(id),
  completed_at timestamptz,
  xp_earned int,
  accuracy_pct int,
  unique(user_id, lesson_id)
);

create table srs_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  vocabulary_id uuid references vocabulary(id),
  due_date timestamptz default now(),
  stability float default 0,
  difficulty float default 5,
  elapsed_days int default 0,
  scheduled_days int default 0,
  reps int default 0,
  lapses int default 0,
  state int default 0,                -- FSRS state enum
  last_review timestamptz,
  unique(user_id, vocabulary_id)
);

create table streaks (
  user_id uuid primary key references auth.users(id),
  current_streak int default 0,
  longest_streak int default 0,
  last_activity_date date,
  total_xp int default 0
);
```

## Drift (SQLite) — Local Device Tables
```dart
// Mirrors Supabase but only data the user has downloaded
// lib/data/local/tables/

class TrackTable extends Table { /* id, slug, name_bn, name_ar */ }
class UnitTable extends Table { /* id, track_id, title_bn, sort_order, downloaded_at */ }
class LessonTable extends Table { /* full lesson data */ }
class ExerciseTable extends Table { /* all exercise fields as JSON */ }
class VocabularyTable extends Table { /* all vocab fields */ }
class SrsCardTable extends Table { /* FSRS fields, synced_at */ }
class UserProgressTable extends Table { /* local progress before sync */ }
class StreakTable extends Table { /* local streak state */ }
class PendingSyncTable extends Table { /* actions waiting to sync */ }
```

## Exercise JSON Schemas (correct_answer field)

```jsonc
// TapToBuild — user assembles sentence from word tiles
{ "words": ["هُوَ", "أُسْتَاذٌ"], "order_matters": true }

// FillInBlank — select or type missing word
{ "sentence": "هُوَ ___ جَدِيدٌ", "blank_index": 1, "answer": "تِلْمِيذٌ" }

// MultipleChoice — 4 options, one correct
{ "options": ["كُوَيْتِيٌّ","سُودَانِيٌّ","مِصْرِيٌّ","نِيجِيرِيٌّ"], "correct_index": 0 }

// DragDrop — match Arabic to Bangla
{ "pairs": [{"ar":"أُسْتَاذٌ","bn":"শিক্ষক"},{"ar":"تِلْمِيذٌ","bn":"ছাত্র"}] }

// WordScramble — rearrange shuffled words into correct sentence
{ "words": ["أَحْمَدُ","كُوَيْتِيٌّ"], "correct": "أَحْمَدُ كُوَيْتِيٌّ" }

// TrueFalse — statement is correct or wrong
{ "statement_ar": "هُوَ تِلْمِيذٌ", "statement_bn": "সে একজন ছাত্র", "is_true": true }
```
