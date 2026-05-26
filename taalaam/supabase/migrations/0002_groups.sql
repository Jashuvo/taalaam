-- Study circles (halaqah groups)

create table groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text unique not null default upper(substring(gen_random_uuid()::text, 1, 6)),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now(),
  max_members int default 10,
  streak_goal int default 0           -- optional shared daily-streak challenge (0 = no goal)
);

create table group_memberships (
  group_id uuid references groups(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  joined_at timestamptz default now(),
  primary key (group_id, user_id)
);

-- indexes
create index on group_memberships (user_id);
create index on group_memberships (group_id);

-- RLS
alter table groups enable row level security;
alter table group_memberships enable row level security;

-- members can read any group they belong to
create policy "members read group" on groups for select
  using (exists (
    select 1 from group_memberships gm
    where gm.group_id = groups.id and gm.user_id = auth.uid()
  ));

-- any logged-in user can create a group (they become creator)
create policy "users create groups" on groups for insert
  with check (created_by = auth.uid());

-- only creator can update or delete
create policy "creator updates group" on groups for update
  using (created_by = auth.uid());
create policy "creator deletes group" on groups for delete
  using (created_by = auth.uid());

-- members can read all memberships in groups they belong to
create policy "members read memberships" on group_memberships for select
  using (
    user_id = auth.uid()
    or exists (
      select 1 from group_memberships gm2
      where gm2.group_id = group_memberships.group_id and gm2.user_id = auth.uid()
    )
  );

-- any logged-in user can join (insert their own row)
create policy "users join groups" on group_memberships for insert
  with check (user_id = auth.uid());

-- users can only remove themselves
create policy "users leave groups" on group_memberships for delete
  using (user_id = auth.uid());
