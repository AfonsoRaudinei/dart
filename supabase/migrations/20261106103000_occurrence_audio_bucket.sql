-- Bucket privado do áudio de 30s da ocorrência.
-- Chave: {userId}/{occurrenceId}.m4a — userId é o dono da linha.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'occurrence-audio',
  'occurrence-audio',
  false,
  2097152,
  ARRAY['audio/mp4', 'audio/aac']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "authenticated select own occurrence audio" ON storage.objects;
CREATE POLICY "authenticated select own occurrence audio"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'occurrence-audio'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "authenticated insert own occurrence audio" ON storage.objects;
CREATE POLICY "authenticated insert own occurrence audio"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'occurrence-audio'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "authenticated update own occurrence audio" ON storage.objects;
CREATE POLICY "authenticated update own occurrence audio"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'occurrence-audio'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'occurrence-audio'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "authenticated delete own occurrence audio" ON storage.objects;
CREATE POLICY "authenticated delete own occurrence audio"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'occurrence-audio'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
