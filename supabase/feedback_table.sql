-- Tabela de feedback in-app (alinhada ao app + dashboard HTML admin)
-- Executar no SQL Editor do Supabase
--
-- Contrato Dart: SupabaseFeedbackRepository.sendFeedback
--   type    = FeedbackType.name          (bug|suggestion|praise)
--   module  = FeedbackModule.storageValue
--   impact  = FeedbackImpact.storageValue (low|medium|high|critical)
--   message = texto do usuário
-- Dashboard admin: https://afonsoraudinei.github.io/Feedback/

CREATE TABLE IF NOT EXISTS public.feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  module TEXT NOT NULL,
  impact TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Migração a partir do schema legado (category) — idempotente
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

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'feedback' AND column_name = 'module'
  ) THEN
    ALTER TABLE public.feedback ADD COLUMN module TEXT NOT NULL DEFAULT 'other';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'feedback' AND column_name = 'impact'
  ) THEN
    ALTER TABLE public.feedback ADD COLUMN impact TEXT NOT NULL DEFAULT 'medium';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'feedback' AND column_name = 'app_version'
  ) THEN
    ALTER TABLE public.feedback DROP COLUMN app_version;
  END IF;
END $$;

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "feedback_insert_own" ON public.feedback;
DROP POLICY IF EXISTS "feedback_select_own" ON public.feedback;

CREATE POLICY "feedback_insert_own" ON public.feedback
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "feedback_select_own" ON public.feedback
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());
