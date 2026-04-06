-- ============================================================
-- SOLOFORTE — FIX-004
-- Corrige handle_new_user: preenche name e role em perfis
-- Remove tabela perfs órfã criada manualmente em 2026-04-06
-- ============================================================

-- 1. Drop tabela órfã (criada manualmente, sem migration)
DROP TABLE IF EXISTS public.perfs;

-- 2. Corrigir função handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.perfis (id, name, role)
  VALUES (
    NEW.id,
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
      NEW.email
    ),
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'role', ''),
      'produtor'
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 3. Atualizar registro existente com name vazio
UPDATE public.perfis
SET name = (
  SELECT COALESCE(
    NULLIF(raw_user_meta_data->>'full_name', ''),
    email
  )
  FROM auth.users
  WHERE auth.users.id = perfis.id
)
WHERE name IS NULL OR name = '';
