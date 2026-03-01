-- ============================================================
-- MIGRATION: Adicionar políticas RLS de ESCRITA
-- Tabelas: marketing_cases, marketing_avaliacoes
-- Executar: colar no SQL Editor do Supabase (sem re-criar tabelas)
-- Data: 28/02/2026
-- ============================================================

-- ── marketing_cases: INSERT ──────────────────────────────────
-- Permite que usuário autenticado crie um novo case
CREATE POLICY "authenticated insert cases" ON marketing_cases
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- ── marketing_cases: UPDATE ──────────────────────────────────
-- Permite upsert via saveCase() (o repositório faz .upsert())
CREATE POLICY "authenticated update cases" ON marketing_cases
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

-- ── marketing_avaliacoes: INSERT ─────────────────────────────
-- Permite inserir avaliações apenas se o case pai existe
CREATE POLICY "authenticated insert avaliacoes" ON marketing_avaliacoes
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM marketing_cases mc
      WHERE mc.id = case_id
    )
  );

-- ── marketing_avaliacoes: UPDATE ─────────────────────────────
-- Permite upsert das avaliações
CREATE POLICY "authenticated update avaliacoes" ON marketing_avaliacoes
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM marketing_cases mc
      WHERE mc.id = case_id
    )
  );

-- ============================================================
-- VERIFICAÇÃO (rodar após aplicar):
-- Deve listar 7 policies no total (3 de leitura + 4 de escrita)
-- ============================================================
-- SELECT policyname, cmd, roles
-- FROM pg_policies
-- WHERE tablename IN ('marketing_cases', 'marketing_avaliacoes')
-- ORDER BY tablename, cmd;
