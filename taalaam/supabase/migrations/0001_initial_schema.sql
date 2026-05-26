-- supabase/migrations/0001_initial_schema.sql
-- Ta'allam initial schema
-- Run via: supabase db reset

-- Enable UUID generation
create extension if not exists "uuid-ossp";

-- ─── CURRICULUM ───────────────────────────────────────────────

create table tracks (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name_ar text not null,
  name_bn text not null,
  name_en text not null,
  description_bn text,
  sort_order int default 0,
  created_at timestamptz default now()
);

create table units (
  id uuid primary key default gen_random_uuid(),
  track_id uuid references tracks(id) on delete cascade,
  slug text not null,
  title_ar text,
  title_bn text not null,
  title_en text,
  description_bn text,
  sort_order int not null,
  status text default 'draft' check (status in ('draft','published')),
  source_material_id uuid,
  created_at timestamptz default now()
);

create table lessons (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid references units(id) on delete cascade,
  title_bn text not null,
  title_ar text,
  sort_order int not null,
  xp_reward int default 10,
  status text default 'draft' check (status in ('draft','published')),
  level text default 'beginner' check (level in ('beginner','intermediate','advanced')),
  created_at timestamptz default now()
);

create table exercises (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references lessons(id) on delete cascade,
  type text not null check (type in (
    'tap_to_build','fill_in_blank','multiple_choice',
    'drag_drop','word_scramble','true_false'
  )),
  sort_order int not null,
  prompt_ar text,
  prompt_bn text,
  prompt_en text,
  correct_answer jsonb not null,
  distractors jsonb,
  audio_url text,
  grammar_note_bn text,
  grammar_note_en text,
  difficulty int default 1 check (difficulty between 1 and 5),
  created_at timestamptz default now()
);

create table vocabulary (
  id uuid primary key default gen_random_uuid(),
  arabic text not null,
  transliteration text,
  meaning_bn text not null,
  meaning_en text,
  root_letters text,
  word_type text check (word_type in ('noun','verb','particle','adjective','proper_noun')),
  gender text check (gender in ('masculine','feminine')),
  audio_url text,
  lesson_id uuid references lessons(id) on delete set null,
  frequency_rank int,
  created_at timestamptz default now()
);

-- ─── CONTENT MANAGEMENT ───────────────────────────────────────

create table source_materials (
  id uuid primary key default gen_random_uuid(),
  filename text not null,
  storage_path text not null,
  file_type text check (file_type in ('pdf','text','image')),
  processing_status text default 'pending' check (
    processing_status in ('pending','processing','done','error')
  ),
  raw_extracted_text text,
  ai_output jsonb,
  error_message text,
  notes text,
  created_at timestamptz default now(),
  processed_at timestamptz
);

-- ─── USER DATA ────────────────────────────────────────────────

create table user_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  lesson_id uuid references lessons(id) on delete cascade,
  completed_at timestamptz default now(),
  xp_earned int default 0,
  accuracy_pct int default 0,
  hearts_remaining int default 5,
  unique(user_id, lesson_id)
);

create table srs_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  vocabulary_id uuid references vocabulary(id) on delete cascade,
  -- FSRS fields
  due_date timestamptz default now(),
  stability float default 0,
  difficulty float default 5,
  elapsed_days int default 0,
  scheduled_days int default 0,
  reps int default 0,
  lapses int default 0,
  state int default 0,
  last_review timestamptz,
  unique(user_id, vocabulary_id)
);

create table streaks (
  user_id uuid primary key references auth.users(id) on delete cascade,
  current_streak int default 0,
  longest_streak int default 0,
  last_activity_date date,
  total_xp int default 0,
  updated_at timestamptz default now()
);

-- ─── INDEXES ──────────────────────────────────────────────────
create index idx_units_track on units(track_id, sort_order);
create index idx_lessons_unit on lessons(unit_id, sort_order);
create index idx_exercises_lesson on exercises(lesson_id, sort_order);
create index idx_vocabulary_lesson on vocabulary(lesson_id);
create index idx_srs_user_due on srs_cards(user_id, due_date);
create index idx_progress_user on user_progress(user_id);

-- ─── RLS (Row Level Security) ─────────────────────────────────
alter table tracks enable row level security;
alter table units enable row level security;
alter table lessons enable row level security;
alter table exercises enable row level security;
alter table vocabulary enable row level security;
alter table user_progress enable row level security;
alter table srs_cards enable row level security;
alter table streaks enable row level security;

-- Public read for published content
create policy "published content is public" on tracks for select using (true);
create policy "published units" on units for select using (status = 'published');
create policy "published lessons" on lessons for select using (status = 'published');
create policy "exercises of published lessons" on exercises for select
  using (exists (select 1 from lessons l where l.id = lesson_id and l.status = 'published'));
create policy "vocabulary of published lessons" on vocabulary for select
  using (lesson_id is null or exists (
    select 1 from lessons l where l.id = lesson_id and l.status = 'published'
  ));

-- Users can only see/edit their own progress
create policy "users own progress" on user_progress
  for all using (auth.uid() = user_id);
create policy "users own srs" on srs_cards
  for all using (auth.uid() = user_id);
create policy "users own streak" on streaks
  for all using (auth.uid() = user_id);

-- ─── SEED DATA ────────────────────────────────────────────────
insert into tracks (slug, name_ar, name_bn, name_en, sort_order) values
  ('conversational', 'عربي محادثة', 'কথ্য আরবি', 'Conversational Arabic', 1),
  ('quranic', 'عربية القرآن', 'কুরআনিক আরবি', 'Quranic Arabic', 2);
