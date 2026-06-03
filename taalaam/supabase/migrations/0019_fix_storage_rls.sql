-- Fix storage RLS: auth.jwt() ->> 'email' returns NULL in newer Supabase projects
-- where JWT email embedding is disabled. Replace with auth.email() throughout.

DROP POLICY IF EXISTS "admins upload raw-content"  ON storage.objects;
DROP POLICY IF EXISTS "admins read raw-content"    ON storage.objects;
DROP POLICY IF EXISTS "admins delete raw-content"  ON storage.objects;

CREATE POLICY "admins upload raw-content" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'raw-content'
    AND auth.email() = 'jubayedsr@gmail.com'
  );

CREATE POLICY "admins read raw-content" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'raw-content'
    AND auth.email() = 'jubayedsr@gmail.com'
  );

CREATE POLICY "admins delete raw-content" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'raw-content'
    AND auth.email() = 'jubayedsr@gmail.com'
  );
