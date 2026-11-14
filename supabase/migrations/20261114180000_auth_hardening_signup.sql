-- ============================================================
-- SOLOFORTE — Hardening de cadastro/login (revisão auth 2026-11-14)
-- 1. handle_new_user: só aceita role produtor|consultor (fallback produtor)
-- 2. Revoga EXECUTE de anon/public em funções SECURITY DEFINER
--    que não devem ser chamadas via /rest/v1/rpc sem login
-- 3. handle_new_user é função de trigger: ninguém precisa de EXECUTE
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
BEGIN
  v_role := lower(trim(coalesce(NEW.raw_user_meta_data->>'role', '')));
  IF v_role NOT IN ('produtor', 'consultor') THEN
    v_role := 'produtor';
  END IF;

  INSERT INTO public.perfis (id, name, role)
  VALUES (
    NEW.id,
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'full_name', ''), NEW.email),
    v_role
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.delete_own_account() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.accept_producer_link_token(text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.check_suspicious_activity(uuid, integer) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.log_security_event(text, jsonb) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.sync_app_settings_from_profile() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_conversation_last_seen(uuid) FROM PUBLIC, anon;
