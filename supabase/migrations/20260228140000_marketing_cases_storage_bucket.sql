-- ============================================================
-- BUCKET: marketing-cases (Supabase Storage)
-- Executar no SQL Editor do Supabase
-- OU criar manualmente via painel Storage > New Bucket
-- ============================================================

-- 1. Criar o bucket público
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'marketing-cases',
  'marketing-cases',
  true,                          -- público: URL sem autenticação
  5242880,                       -- 5 MB por arquivo
  ARRAY['image/jpeg','image/png','image/webp','image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy: qualquer um pode LER (download de fotos)
DROP POLICY IF EXISTS "public read marketing photos" ON storage.objects;
CREATE POLICY "public read marketing photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'marketing-cases');

-- 3. Policy: apenas autenticado pode FAZER UPLOAD
DROP POLICY IF EXISTS "authenticated upload marketing photos" ON storage.objects;
CREATE POLICY "authenticated upload marketing photos"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'marketing-cases'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 4. Policy: apenas autenticado pode DELETAR sua própria foto
DROP POLICY IF EXISTS "authenticated delete marketing photos" ON storage.objects;
CREATE POLICY "authenticated delete marketing photos"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'marketing-cases'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================
-- VERIFICAÇÃO (rodar após aplicar):
-- SELECT name, public FROM storage.buckets WHERE id = 'marketing-cases';
-- ============================================================
