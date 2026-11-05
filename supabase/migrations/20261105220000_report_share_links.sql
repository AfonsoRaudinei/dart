-- ============================================================
-- SoloForte — Links públicos de relatório HTML (WhatsApp share)
-- Bucket report-shares + metadados por token (RLS owner-only)
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'report-shares',
  'report-shares',
  true,
  15728640,
  ARRAY['text/html']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "public read report shares" ON storage.objects;

DROP POLICY IF EXISTS "authenticated read own report shares" ON storage.objects;
CREATE POLICY "authenticated read own report shares"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'report-shares'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "authenticated upload own report shares" ON storage.objects;
CREATE POLICY "authenticated upload own report shares"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'report-shares'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "authenticated update own report shares" ON storage.objects;
CREATE POLICY "authenticated update own report shares"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'report-shares'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'report-shares'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "authenticated delete own report shares" ON storage.objects;
CREATE POLICY "authenticated delete own report shares"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'report-shares'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE TABLE IF NOT EXISTS public.report_share_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL UNIQUE,
  title text NOT NULL,
  storage_path text NOT NULL,
  public_url text NOT NULL,
  report_kind text,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_report_share_links_user_id
  ON public.report_share_links(user_id);

ALTER TABLE public.report_share_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "report_share_links select own" ON public.report_share_links;
CREATE POLICY "report_share_links select own"
  ON public.report_share_links FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "report_share_links insert own" ON public.report_share_links;
CREATE POLICY "report_share_links insert own"
  ON public.report_share_links FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "report_share_links update own" ON public.report_share_links;
CREATE POLICY "report_share_links update own"
  ON public.report_share_links FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "report_share_links delete own" ON public.report_share_links;
CREATE POLICY "report_share_links delete own"
  ON public.report_share_links FOR DELETE TO authenticated
  USING (user_id = auth.uid());

COMMENT ON TABLE public.report_share_links IS
  'Metadados de HTML publicado no bucket report-shares; acesso público via URL de storage + token.';
