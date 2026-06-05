-- ============================================================
-- SOLOFORTE — Report Branding
-- Marca customizada de relatório por usuário/emissor.
-- ============================================================

ALTER TABLE public.perfis
  ADD COLUMN IF NOT EXISTS report_brand_name text,
  ADD COLUMN IF NOT EXISTS report_logo_url text;

COMMENT ON COLUMN public.perfis.report_brand_name IS
  'Nome da marca/empresa exibido em cabeçalhos e rodapés dos relatórios.';

COMMENT ON COLUMN public.perfis.report_logo_url IS
  'URL pública do logo customizado usado nos relatórios.';

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'report-branding',
  'report-branding',
  true,
  2097152,
  ARRAY['image/jpeg','image/png','image/webp','image/heic']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "public read report branding logos" ON storage.objects;
CREATE POLICY "public read report branding logos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'report-branding');

DROP POLICY IF EXISTS "authenticated upload own report branding logos" ON storage.objects;
CREATE POLICY "authenticated upload own report branding logos"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'report-branding'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "authenticated update own report branding logos" ON storage.objects;
CREATE POLICY "authenticated update own report branding logos"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'report-branding'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'report-branding'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "authenticated delete own report branding logos" ON storage.objects;
CREATE POLICY "authenticated delete own report branding logos"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'report-branding'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
