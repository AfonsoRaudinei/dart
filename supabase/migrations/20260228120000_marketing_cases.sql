-- Tabela principal
CREATE TABLE IF NOT EXISTS marketing_cases (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  tipo                  TEXT NOT NULL CHECK (tipo IN ('resultado','antes_depois','avaliacao')),
  visibilidade          TEXT NOT NULL CHECK (visibilidade IN ('ouro','prata','bronze')),
  lat                   NUMERIC(10,7) NOT NULL,
  lng                   NUMERIC(10,7) NOT NULL,
  localizacao_texto     TEXT NOT NULL,
  produtor_fazenda      TEXT NOT NULL,
  produto_utilizado     TEXT NOT NULL,
  produtividade_valor   NUMERIC,
  produtividade_unidade TEXT,
  nome_vendedor         TEXT,
  telefone_vendedor     TEXT,
  descricao             TEXT,
  foto_principal_url    TEXT,
  foto_antes_url        TEXT,
  foto_depois_url       TEXT,
  ganho_produtividade   TEXT,
  economia_gerada       TEXT,
  quantidade_produzida  NUMERIC,
  nome_talhao           TEXT,
  tamanho_ha            NUMERIC,
  roi_investimento      NUMERIC,
  roi_retorno           NUMERIC,
  roi_calculado         NUMERIC,
  conclusao             TEXT,
  ativo                 BOOLEAN NOT NULL DEFAULT true,
  criado_em             TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em         TIMESTAMPTZ NOT NULL DEFAULT now(),
  deletado_em           TIMESTAMPTZ,
  sync_status           TEXT NOT NULL DEFAULT 'local_only'
);

-- Avaliações dinâmicas (filhos)
CREATE TABLE IF NOT EXISTS marketing_avaliacoes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id         UUID NOT NULL REFERENCES marketing_cases(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ordem           INT NOT NULL,
  layout          TEXT NOT NULL DEFAULT 'duas_fotos',
  colapsado       BOOLEAN NOT NULL DEFAULT false,
  lado_a_label    TEXT NOT NULL DEFAULT 'Produto A',
  lado_a_foto_url TEXT,
  lado_a_cultura  TEXT,
  lado_a_obs      TEXT,
  lado_b_label    TEXT NOT NULL DEFAULT 'Produto B',
  lado_b_foto_url TEXT,
  lado_b_cultura  TEXT,
  lado_b_obs      TEXT
);

-- RLS
ALTER TABLE marketing_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_avaliacoes ENABLE ROW LEVEL SECURITY;

ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS tipo TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS visibilidade TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS lat NUMERIC(10,7);
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS lng NUMERIC(10,7);
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS localizacao_texto TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS produtor_fazenda TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS produto_utilizado TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS produtividade_valor NUMERIC;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS produtividade_unidade TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS nome_vendedor TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS telefone_vendedor TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS descricao TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS foto_principal_url TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS foto_antes_url TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS foto_depois_url TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS ganho_produtividade TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS economia_gerada TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS quantidade_produzida NUMERIC;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS nome_talhao TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS tamanho_ha NUMERIC;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS roi_investimento NUMERIC;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS roi_retorno NUMERIC;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS roi_calculado NUMERIC;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS conclusao TEXT;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS ativo BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS criado_em TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS deletado_em TIMESTAMPTZ;
ALTER TABLE marketing_cases ADD COLUMN IF NOT EXISTS sync_status TEXT NOT NULL DEFAULT 'local_only';

ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS ordem INT NOT NULL DEFAULT 0;
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS layout TEXT NOT NULL DEFAULT 'duas_fotos';
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS colapsado BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS lado_a_label TEXT NOT NULL DEFAULT 'Produto A';
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS lado_a_foto_url TEXT;
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS lado_a_cultura TEXT;
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS lado_a_obs TEXT;
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS lado_b_label TEXT NOT NULL DEFAULT 'Produto B';
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS lado_b_foto_url TEXT;
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS lado_b_cultura TEXT;
ALTER TABLE marketing_avaliacoes ADD COLUMN IF NOT EXISTS lado_b_obs TEXT;

-- Ouro: leitura pública sem autenticação
DROP POLICY IF EXISTS "ouro public read" ON marketing_cases;
CREATE POLICY "ouro public read" ON marketing_cases
  FOR SELECT USING (
    visibilidade = 'ouro'
    AND ativo = true
    AND deletado_em IS NULL
  );

-- Prata e Bronze: leitura apenas autenticado
DROP POLICY IF EXISTS "prata bronze auth read" ON marketing_cases;
CREATE POLICY "prata bronze auth read" ON marketing_cases
  FOR SELECT TO authenticated USING (
    ativo = true
    AND deletado_em IS NULL
  );

-- Avaliações seguem o case pai
DROP POLICY IF EXISTS "avaliacoes public read" ON marketing_avaliacoes;
CREATE POLICY "avaliacoes public read" ON marketing_avaliacoes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM marketing_cases mc
      WHERE mc.id = marketing_avaliacoes.case_id
      AND mc.ativo = true
      AND mc.deletado_em IS NULL
    )
  );

-- ────────────────────────────────────────────────────────────
-- POLÍTICAS DE ESCRITA (INSERT / UPDATE)
-- Exigem usuário autenticado via supabase.auth
-- ────────────────────────────────────────────────────────────

-- Usuário autenticado pode criar novos cases
DROP POLICY IF EXISTS "authenticated insert cases" ON marketing_cases;
CREATE POLICY "authenticated insert cases" ON marketing_cases
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Usuário autenticado pode atualizar apenas seus cases (upsert no saveCase)
DROP POLICY IF EXISTS "authenticated update cases" ON marketing_cases;
CREATE POLICY "authenticated update cases" ON marketing_cases
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Usuário autenticado pode inserir avaliações de um case existente
DROP POLICY IF EXISTS "authenticated insert avaliacoes" ON marketing_avaliacoes;
CREATE POLICY "authenticated insert avaliacoes" ON marketing_avaliacoes
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND
    EXISTS (
      SELECT 1 FROM marketing_cases mc
      WHERE mc.id = case_id
        AND mc.user_id = auth.uid()
    )
  );

-- Usuário autenticado pode atualizar avaliações (upsert)
DROP POLICY IF EXISTS "authenticated update avaliacoes" ON marketing_avaliacoes;
CREATE POLICY "authenticated update avaliacoes" ON marketing_avaliacoes
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND
    EXISTS (
      SELECT 1 FROM marketing_cases mc
      WHERE mc.id = case_id
        AND mc.user_id = auth.uid()
    )
  );



-- Seed de teste removido: bancos com isolamento por usuario exigem user_id.
