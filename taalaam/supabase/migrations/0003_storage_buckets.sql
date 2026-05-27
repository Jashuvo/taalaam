-- Storage bucket for admin-uploaded source materials (PDFs, images, text)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'raw-content',
  'raw-content',
  false,
  52428800,
  array['application/pdf','image/jpeg','image/png','image/gif','image/webp','text/plain']
)
on conflict (id) do nothing;

-- Admins can upload
create policy "admins upload raw-content"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'raw-content'
    and (auth.jwt() ->> 'email') in ('jubayedsr@gmail.com')
  );

-- Admins can read/download
create policy "admins read raw-content"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'raw-content'
    and (auth.jwt() ->> 'email') in ('jubayedsr@gmail.com')
  );

-- Admins can delete
create policy "admins delete raw-content"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'raw-content'
    and (auth.jwt() ->> 'email') in ('jubayedsr@gmail.com')
  );
