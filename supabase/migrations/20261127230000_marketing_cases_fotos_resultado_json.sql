-- Resultado com múltiplas fotos (ADR-065): lista de URLs (JSON array em TEXT).
-- foto_principal_url continua sendo a 1ª foto (capa legada).

ALTER TABLE public.marketing_cases
  ADD COLUMN IF NOT EXISTS fotos_resultado_json TEXT;

COMMENT ON COLUMN public.marketing_cases.fotos_resultado_json IS
  'JSON array (string) com 1–5 URLs de fotos do case Resultado; a 1ª espelha foto_principal_url.';
