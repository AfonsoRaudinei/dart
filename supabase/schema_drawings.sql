-- ============================================================
-- SoloForte — Supabase Schema: drawings
-- Executar no SQL Editor do Supabase Dashboard
-- Idempotente: seguro para re-executar
-- ADR de referência: ADR-021 (drawing/ bounded context)
-- Data: Abr/2026
-- ============================================================

-- 1. TABELA
CREATE TABLE IF NOT EXISTS drawings (
  id            TEXT        PRIMARY KEY,
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  geometry      JSONB       NOT NULL DEFAULT '{}',
  properties    JSONB       NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at    TIMESTAMPTZ          DEFAULT NULL
);

-- 2. ROW LEVEL SECURITY
ALTER TABLE drawings ENABLE ROW LEVEL SECURITY;

-- 3. POLÍTICAS RLS (DROP IF EXISTS para idempotência)
DROP POLICY IF EXISTS "drawings_select" ON drawings;
CREATE POLICY "drawings_select"
  ON drawings FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "drawings_insert" ON drawings;
CREATE POLICY "drawings_insert"
  ON drawings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "drawings_update" ON drawings;
CREATE POLICY "drawings_update"
  ON drawings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE não exposto — exclusão lógica via deleted_at.
-- Adicionar política de hard delete somente se necessário no futuro.

-- 4. ÍNDICE — fetchUpdates (user_id + updated_at DESC)
CREATE INDEX IF NOT EXISTS idx_drawings_user_updated
  ON drawings (user_id, updated_at DESC);

-- 5. ÍNDICE — soft delete filter (user_id + deleted_at)
CREATE INDEX IF NOT EXISTS idx_drawings_user_deleted
  ON drawings (user_id, deleted_at);

-- ============================================================
-- VERIFICAÇÃO (rodar após execução para confirmar)
-- ============================================================
-- SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'drawings';
-- SELECT policyname, cmd FROM pg_policies WHERE tablename = 'drawings';
-- SELECT indexname FROM pg_indexes WHERE tablename = 'drawings';
