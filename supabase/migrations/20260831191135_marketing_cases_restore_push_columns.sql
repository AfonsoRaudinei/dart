-- Espelho local da migration remota 20260831191135 (aplicada pelo painel/MCP).
ALTER TABLE public.marketing_cases
  ADD COLUMN IF NOT EXISTS data_case timestamptz,
  ADD COLUMN IF NOT EXISTS prod_sem_produto numeric,
  ADD COLUMN IF NOT EXISTS prod_com_produto numeric,
  ADD COLUMN IF NOT EXISTS unidade_produtividade text,
  ADD COLUMN IF NOT EXISTS custo_produto_por_ha numeric,
  ADD COLUMN IF NOT EXISTS valor_grao numeric,
  ADD COLUMN IF NOT EXISTS client_id uuid,
  ADD COLUMN IF NOT EXISTS parametros_json text,
  ADD COLUMN IF NOT EXISTS avaliacoes_json text,
  ADD COLUMN IF NOT EXISTS conclusao_tecnica text;

NOTIFY pgrst, 'reload schema';
