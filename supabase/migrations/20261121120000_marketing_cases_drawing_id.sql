-- ADR-064: área do Resultado/Avaliação é o polígono drawings.tipo = teste.
-- TEXT, sem FK: o desenho pode existir só no SQLite do aparelho.

ALTER TABLE public.marketing_cases
  ADD COLUMN IF NOT EXISTS drawing_id TEXT;

COMMENT ON COLUMN public.marketing_cases.drawing_id IS
  'Id do polígono drawings (tipo teste) que é a área deste case.';

CREATE INDEX IF NOT EXISTS idx_marketing_cases_drawing_id
  ON public.marketing_cases (drawing_id);
