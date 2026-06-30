-- ============================================================
-- SOLOFORTE — FIX-002
-- Tabela: marketing_avaliacoes
-- Problema: policy FOR ALL sem WITH CHECK bloqueia INSERT
-- Referência: Auditoria Flutter ↔ Supabase (2026-03-01)
-- ============================================================

-- PASSO 1: Remover policy genérica problemática
DROP POLICY IF EXISTS "marketing_avaliacoes_own" ON marketing_avaliacoes;

-- PASSO 2: Criar policies granulares e explícitas

-- SELECT: usuário lê apenas suas próprias avaliações
DROP POLICY IF EXISTS "avaliacoes_select_own" ON marketing_avaliacoes;
CREATE POLICY "avaliacoes_select_own"
  ON marketing_avaliacoes
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- INSERT: usuário insere apenas avaliações com seu próprio user_id
DROP POLICY IF EXISTS "avaliacoes_insert_own" ON marketing_avaliacoes;
CREATE POLICY "avaliacoes_insert_own"
  ON marketing_avaliacoes
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: usuário atualiza apenas suas próprias avaliações
DROP POLICY IF EXISTS "avaliacoes_update_own" ON marketing_avaliacoes;
CREATE POLICY "avaliacoes_update_own"
  ON marketing_avaliacoes
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- VERIFICAÇÃO FINAL
-- Executar após a migration para confirmar as 3 policies:
-- ============================================================
-- SELECT
--   policyname,
--   cmd,
--   qual,
--   with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND tablename = 'marketing_avaliacoes'
-- ORDER BY cmd;
--
-- Resultado esperado: 3 linhas (INSERT, SELECT, UPDATE)
