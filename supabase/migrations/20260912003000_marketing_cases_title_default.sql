-- Live legado: title TEXT NOT NULL sem default → INSERT PT-only falha 23502
-- e o app rebaixa o case a rascunho (sem pin no mapa).
ALTER TABLE public.marketing_cases
  ALTER COLUMN title SET DEFAULT '';

ALTER TABLE public.marketing_cases
  ALTER COLUMN title DROP NOT NULL;
