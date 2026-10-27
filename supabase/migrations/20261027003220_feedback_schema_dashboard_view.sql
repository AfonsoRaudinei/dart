-- Alinha public.feedback ao contrato Dart (type/module/impact) e cria
-- a view de leitura do dashboard GitHub Pages (anon, sem user_id).
--
-- A migration 20260603000000_feedback_module_impact usou CREATE TABLE IF NOT
-- EXISTS e não alterou a tabela legado que ainda tinha `category`.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'feedback' AND column_name = 'category'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'feedback' AND column_name = 'type'
  ) THEN
    ALTER TABLE public.feedback RENAME COLUMN category TO type;
  END IF;
END $$;

ALTER TABLE public.feedback
  ADD COLUMN IF NOT EXISTS module text NOT NULL DEFAULT 'other';

ALTER TABLE public.feedback
  ADD COLUMN IF NOT EXISTS impact text NOT NULL DEFAULT 'medium';

ALTER TABLE public.feedback DROP COLUMN IF EXISTS app_version;
ALTER TABLE public.feedback DROP COLUMN IF EXISTS rating;

CREATE OR REPLACE VIEW public.feedback_dashboard AS
SELECT id, type, module, impact, message, created_at
FROM public.feedback;

ALTER VIEW public.feedback_dashboard SET (security_invoker = false);

GRANT SELECT ON public.feedback_dashboard TO anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.feedback_dashboard FROM anon, authenticated;
