-- Remover tabela antiga do teste anterior para limpar o banco
DROP TABLE IF EXISTS marketing_pins CASCADE;

-- Tabela principal
CREATE TABLE marketing_cases (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
CREATE TABLE marketing_avaliacoes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id         UUID NOT NULL REFERENCES marketing_cases(id) ON DELETE CASCADE,
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

-- Ouro: leitura pública sem autenticação
CREATE POLICY "ouro public read" ON marketing_cases
  FOR SELECT USING (
    visibilidade = 'ouro'
    AND ativo = true
    AND deletado_em IS NULL
  );

-- Prata e Bronze: leitura apenas autenticado
CREATE POLICY "prata bronze auth read" ON marketing_cases
  FOR SELECT TO authenticated USING (
    ativo = true
    AND deletado_em IS NULL
  );

-- Avaliações seguem o case pai
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
CREATE POLICY "authenticated insert cases" ON marketing_cases
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- Usuário autenticado pode atualizar seus cases (upsert no saveCase)
CREATE POLICY "authenticated update cases" ON marketing_cases
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

-- Usuário autenticado pode inserir avaliações de um case existente
CREATE POLICY "authenticated insert avaliacoes" ON marketing_avaliacoes
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM marketing_cases mc
      WHERE mc.id = case_id
    )
  );

-- Usuário autenticado pode atualizar avaliações (upsert)
CREATE POLICY "authenticated update avaliacoes" ON marketing_avaliacoes
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM marketing_cases mc
      WHERE mc.id = case_id
    )
  );



-- Seed Ouro de teste (splash screen)
INSERT INTO marketing_cases 
  (tipo, visibilidade, lat, lng, localizacao_texto, produtor_fazenda, produto_utilizado, produtividade_valor, produtividade_unidade, descricao, foto_principal_url, sync_status) 
VALUES
  ('resultado', 'ouro', -23.5505, -46.6333, 'Fazenda Estrela - SP', 'João Agricultor', 'SojaMax Top', 85.5, 'scHa', 'Aumento visível no vigor e controle foliar', 'https://picsum.photos/seed/soja/400/600', 'synced');
