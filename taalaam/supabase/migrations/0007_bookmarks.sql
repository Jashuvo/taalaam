-- Bookmarks table (mirrors local Drift bookmarks table)
create table bookmarks (
  id text primary key,                       -- '{user_id}_{lesson_id}'
  user_id uuid references auth.users(id) on delete cascade,
  lesson_id uuid references lessons(id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, lesson_id)
);

-- RLS: users can only see and manage their own bookmarks
alter table bookmarks enable row level security;

create policy "Users manage own bookmarks"
  on bookmarks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
