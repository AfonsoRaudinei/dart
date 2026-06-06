-- ============================================================
-- SOLOFORTE — FIX-001
-- Módulo: planos/
-- Referência: ADR-012 Seção 4
-- Data: 2026-03-01
-- ============================================================

-- ------------------------------------------------------------
-- TABELA 1: user_plans
-- Registra planos ativos por usuário
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_plans (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plano       TEXT        NOT NULL CHECK (plano IN ('bronze', 'prata', 'ouro')),
  origem      TEXT        NOT NULL CHECK (origem IN ('pagamento', 'indicacao')),
  ativo       BOOLEAN     NOT NULL DEFAULT true,
  iniciou_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
  expira_em   TIMESTAMPTZ NOT NULL,
  payment_id  TEXT,
  criado_em   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_plans ENABLE ROW LEVEL SECURITY;

-- Usuário vê apenas o próprio plano
DROP POLICY IF EXISTS "user sees own plan" ON user_plans;
CREATE POLICY "user sees own plan"
  ON user_plans
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Apenas o sistema (webhook/service_role) insere planos
-- Flutter NÃO insere diretamente — o webhook do Mercado Pago ativa via Edge Function
-- Por isso: sem policy INSERT para authenticated (intencional — ADR-012 Seção 5)

-- ------------------------------------------------------------
-- TABELA 2: referral_codes
-- Um código único por usuário para indicações
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS referral_codes (
  id                    UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID  NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  code                  TEXT  NOT NULL UNIQUE,
  indicacoes_validadas  INT   NOT NULL DEFAULT 0,
  criado_em             TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;

-- Usuário vê apenas o próprio código
DROP POLICY IF EXISTS "user sees own referral code" ON referral_codes;
CREATE POLICY "user sees own referral code"
  ON referral_codes
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Usuário pode inserir o próprio código (gerado no cadastro)
DROP POLICY IF EXISTS "user inserts own referral code" ON referral_codes;
CREATE POLICY "user inserts own referral code"
  ON referral_codes
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ------------------------------------------------------------
-- TABELA 3: referrals
-- Registro de cada indicação realizada
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS referrals (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referred_id UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code        TEXT        NOT NULL,
  status      TEXT        NOT NULL DEFAULT 'pendente'
                          CHECK (status IN ('pendente', 'validada', 'expirada')),
  criado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),
  validado_em TIMESTAMPTZ,
  expira_em   TIMESTAMPTZ NOT NULL
);

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Quem indicou vê suas indicações
DROP POLICY IF EXISTS "referrer sees own referrals" ON referrals;
CREATE POLICY "referrer sees own referrals"
  ON referrals
  FOR SELECT
  TO authenticated
  USING (referrer_id = auth.uid());

-- ------------------------------------------------------------
-- pg_cron: expiração diária de planos (00:00 UTC)
-- ATENÇÃO: Requer extensão pg_cron ativa no Supabase
-- Verificar: Database → Extensions → pg_cron
-- ------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_extension
    WHERE extname = 'pg_cron'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM cron.job
      WHERE jobname = 'expire-plans'
    ) THEN
      PERFORM cron.schedule(
        'expire-plans',
        '0 0 * * *',
        'UPDATE user_plans SET ativo = false WHERE ativo = true AND expira_em < now();'
      );
    END IF;
  END IF;
END $$;

-- ------------------------------------------------------------
-- VERIFICAÇÃO FINAL
-- Após executar, rodar este SELECT para confirmar criação:
-- ------------------------------------------------------------
-- SELECT table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'public'
--   AND table_name IN ('user_plans', 'referral_codes', 'referrals')
-- ORDER BY table_name;
-- Resultado esperado: 3 linhas
