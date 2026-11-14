-- Republicação do produtor: agrupa publicações do mesmo case (source_case_id → raiz).
ALTER TABLE marketing_cases
  ADD COLUMN IF NOT EXISTS source_case_id UUID REFERENCES marketing_cases(id);

CREATE INDEX IF NOT EXISTS marketing_cases_source_case_id_idx
  ON marketing_cases (source_case_id)
  WHERE source_case_id IS NOT NULL;