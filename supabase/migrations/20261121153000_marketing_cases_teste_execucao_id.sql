-- Rastreabilidade: case de avaliação vinculado a uma TesteExecucao (snapshot no case).

ALTER TABLE public.marketing_cases
  ADD COLUMN IF NOT EXISTS teste_execucao_id TEXT;

COMMENT ON COLUMN public.marketing_cases.teste_execucao_id IS
  'Id de teste_execucoes selecionado na avaliação (referência; dados exibidos são snapshot).';

CREATE INDEX IF NOT EXISTS idx_marketing_cases_teste_execucao_id
  ON public.marketing_cases (teste_execucao_id);