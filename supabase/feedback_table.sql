-- ============================================================
-- SoloForte — Tabela: feedback
-- Executar TERCEIRO no SQL Editor do Supabase Dashboard
-- Seguro para re-executar (usa IF NOT EXISTS e DROP IF EXISTS)
--
-- Pré-requisito: supabase_schema.sql já executado
-- Usado em: lib/modules/feedback/presentation/screens/feedback_screen.dart
-- Ver guia completo: docs/SUPABASE_MANUAL.md
-- ============================================================

CREATE TABLE IF NOT EXISTS public.feedback (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo        TEXT        NOT NULL,  -- 'bug' | 'sugestao' | 'elogio' | 'outro'
  mensagem    TEXT        NOT NULL,
  plataforma  TEXT,                  -- 'ios' | 'android'
  app_version TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

-- Política: cada usuário gerencia apenas o próprio feedback
DROP POLICY IF EXISTS "Users manage own feedback" ON public.feedback;
CREATE POLICY "Users manage own feedback" ON public.feedback
  FOR ALL TO authenticated
  USING    (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_feedback_user_id    ON public.feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON public.feedback(created_at DESC);
