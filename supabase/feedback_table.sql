-- DEPRECATED: use supabase/migrations/20260811000000_feedbacks_dashboard.sql
-- Tabela oficial: public.feedbacks (colunas tipo, modulo, impacto, mensagem)
-- Dashboard: https://afonsoraudinei.github.io/Feedback/

-- Legado (category/message) — não usar no app v1.34+

CREATE TABLE IF NOT EXISTS public.feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  message TEXT NOT NULL,
  app_version TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "feedback_insert_own" ON public.feedback;
DROP POLICY IF EXISTS "feedback_select_own" ON public.feedback;

CREATE POLICY "feedback_insert_own" ON public.feedback
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "feedback_select_own" ON public.feedback
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());
