-- ============================================================
-- SoloForte — RPC: delete_own_account
-- Executar SEGUNDO no SQL Editor do Supabase Dashboard
-- Seguro para re-executar (usa CREATE OR REPLACE)
--
-- Pré-requisito: supabase_schema.sql já executado
-- Usado em: lib/core/auth/auth_service.dart
-- Ver guia completo: docs/SUPABASE_MANUAL.md
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _uid UUID := auth.uid();
BEGIN
  -- Remove dados nas tabelas públicas (filhos antes dos pais)
  DELETE FROM public.occurrences
    WHERE visit_session_id IN (
      SELECT id FROM public.visit_sessions WHERE cliente_id = _uid
    );

  DELETE FROM public.visit_reports
    WHERE visit_session_id IN (
      SELECT id FROM public.visit_sessions WHERE cliente_id = _uid
    );

  DELETE FROM public.visit_sessions WHERE cliente_id = _uid;

  DELETE FROM public.fields
    WHERE fazenda_id IN (
      SELECT id FROM public.farms WHERE cliente_id = _uid
    );

  DELETE FROM public.farms        WHERE cliente_id = _uid;
  DELETE FROM public.agenda_events WHERE cliente_id = _uid;
  DELETE FROM public.clients      WHERE id = _uid;

  -- Remove feedback (tabela criada por feedback_table.sql)
  DELETE FROM public.feedback WHERE user_id = _uid;

  -- Remove a conta do Auth (requer SECURITY DEFINER)
  DELETE FROM auth.users WHERE id = _uid;
END;
$$;

-- Conceder execução apenas para usuários autenticados
REVOKE EXECUTE ON FUNCTION public.delete_own_account() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
