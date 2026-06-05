-- Audio storage bucket for listen_select exercise audio files
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio',
  'audio',
  true,
  1048576,
  ARRAY['audio/wav','audio/mpeg','audio/ogg','audio/webm']
)
ON CONFLICT (id) DO NOTHING;

-- Public read (learners stream audio files)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
    AND policyname = 'Public audio read'
  ) THEN
    CREATE POLICY "Public audio read"
      ON storage.objects FOR SELECT TO public
      USING (bucket_id = 'audio');
  END IF;
END $$;

-- Service role write (edge function uploads generated audio)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
    AND policyname = 'Service role audio write'
  ) THEN
    CREATE POLICY "Service role audio write"
      ON storage.objects FOR ALL TO service_role
      USING (bucket_id = 'audio');
  END IF;
END $$;
