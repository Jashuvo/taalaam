-- Enable RLS on source_materials (policy already added in 0004)
alter table source_materials enable row level security;

-- Exercises: admin can see ALL (including drafts)
create policy "admin can see all exercises" on exercises
  for select to authenticated
  using (
    (auth.jwt() ->> 'email') = 'jubayedsr@gmail.com'
    or lesson_id in (select id from lessons where status = 'published')
  );

-- Exercises: admin full write access
create policy "admin can insert exercises" on exercises
  for insert to authenticated
  with check ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

create policy "admin can update exercises" on exercises
  for update to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

create policy "admin can delete exercises" on exercises
  for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

-- Vocabulary: admin can see ALL (including drafts)
create policy "admin can see all vocabulary" on vocabulary
  for select to authenticated
  using (
    (auth.jwt() ->> 'email') = 'jubayedsr@gmail.com'
    or lesson_id in (select id from lessons where status = 'published')
  );

-- Vocabulary: admin full write access
create policy "admin can insert vocabulary" on vocabulary
  for insert to authenticated
  with check ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

create policy "admin can update vocabulary" on vocabulary
  for update to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

create policy "admin can delete vocabulary" on vocabulary
  for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');
