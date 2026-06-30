-- Executar no SQL Editor do Supabase (Auth + exclusão de conta in-app)

-- Função para o usuário autenticado excluir a própria conta.
-- Requer: GRANT EXECUTE TO authenticated
-- ON DELETE CASCADE nas tabelas filhas garante limpeza automática.
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;