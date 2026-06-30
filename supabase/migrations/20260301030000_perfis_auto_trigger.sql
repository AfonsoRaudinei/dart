-- ============================================================
-- SOLOFORTE — FIX-003
-- Trigger: Criação automática de perfil no cadastro
-- Elimina dependência de sessão no Flutter para INSERT
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. Função que cria perfil automaticamente ao cadastrar
--    SECURITY DEFINER = bypassa RLS (executa como owner)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.perfis (id)
  VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 2. Trigger: dispara após INSERT em auth.users
-- ────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();

-- ────────────────────────────────────────────────────────────
-- 3. Função auxiliar: atualizar updated_at automaticamente
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_perfis_updated_at ON public.perfis;

CREATE TRIGGER update_perfis_updated_at
  BEFORE UPDATE ON public.perfis
  FOR EACH ROW
  EXECUTE PROCEDURE public.update_updated_at_column();

-- ────────────────────────────────────────────────────────────
-- 4. Remover policy INSERT que não é mais necessária
--    (INSERT agora é feito pelo trigger com SECURITY DEFINER)
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can insert own profile" ON perfis;

-- Manter SELECT e UPDATE (usuário lê e edita seu próprio perfil)
-- Policies "Users can view own profile" e "Users can update own profile"
-- já existem da migration anterior (20260301000000)

-- ────────────────────────────────────────────────────────────
-- 5. Criar perfis retroativos para usuários existentes
--    que foram cadastrados ANTES deste trigger existir
-- ────────────────────────────────────────────────────────────
INSERT INTO public.perfis (id)
SELECT id FROM auth.users
WHERE id NOT IN (SELECT id FROM public.perfis)
ON CONFLICT (id) DO NOTHING;

-- ────────────────────────────────────────────────────────────
-- VERIFICAÇÃO FINAL
-- ────────────────────────────────────────────────────────────
-- SELECT trigger_name, event_object_table
-- FROM information_schema.triggers
-- WHERE trigger_schema = 'public' OR event_object_schema = 'auth';
--
-- Resultado esperado:
--   on_auth_user_created  | users
--   update_perfis_updated_at | perfis
