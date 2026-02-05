-- Arquivo para executar no Dashboard do Supabase (SQL Editor)

-- 1. Create Tables
CREATE TABLE IF NOT EXISTS public.clients (
  id UUID PRIMARY KEY,
  nome TEXT NOT NULL,
  documento TEXT,
  telefone TEXT,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.farms (
  id UUID PRIMARY KEY,
  cliente_id UUID NOT NULL REFERENCES public.clients(id),
  nome TEXT NOT NULL,
  area_total REAL,
  municipio TEXT,
  uf TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.fields (
  id UUID PRIMARY KEY,
  fazenda_id UUID NOT NULL REFERENCES public.farms(id),
  codigo TEXT,
  nome TEXT NOT NULL,
  area_produtiva REAL,
  bordadura_geo JSONB,
  centro_geo JSONB,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

-- 2. Enable RLS
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fields ENABLE ROW LEVEL SECURITY;

-- 3. Create Policies (Authenticated Access Only) (Adjust as per project RLS needs - currently using simplified auth)
-- Clients
CREATE POLICY "Enable all for authenticated users" ON public.clients
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Farms
CREATE POLICY "Enable all for authenticated users" ON public.farms
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Fields
CREATE POLICY "Enable all for authenticated users" ON public.fields
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);
