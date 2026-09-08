-- Marketing cases: vínculo opcional de cliente (alinhado ao app local)
ALTER TABLE public.marketing_cases
ADD COLUMN IF NOT EXISTS client_id UUID NULL REFERENCES public.clients(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_marketing_cases_client_id ON public.marketing_cases(client_id);
