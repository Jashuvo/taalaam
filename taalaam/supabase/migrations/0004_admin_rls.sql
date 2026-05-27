-- Admin RLS policies: allow admin to see drafts and publish content
-- Admin is identified by email 'jubayedsr@gmail.com'

-- Units: admin can see ALL statuses (drafts + published)
create policy "admin can see all units" on units
  for select to authenticated
  using (
    (auth.jwt() ->> 'email') = 'jubayedsr@gmail.com'
    or status = 'published'
  );

-- Units: admin can update (publish/unpublish)
create policy "admin can update units" on units
  for update to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

-- Lessons: admin can see ALL statuses
create policy "admin can see all lessons" on lessons
  for select to authenticated
  using (
    (auth.jwt() ->> 'email') = 'jubayedsr@gmail.com'
    or status = 'published'
  );

-- Lessons: admin can update (publish/unpublish)
create policy "admin can update lessons" on lessons
  for update to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

-- Source materials: admin can see + insert
create policy "admin can manage source materials" on source_materials
  for all to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');
