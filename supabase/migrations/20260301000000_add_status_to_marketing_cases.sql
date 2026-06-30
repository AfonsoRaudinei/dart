-- Migração: Adicionar campo 'status' à tabela marketing_cases
-- Data: 2026-03-01
-- Descrição: Permite criar rascunhos de cases antes da publicação

-- Adiciona a coluna status com valor padrão 'published' para retrocompatibilidade
ALTER TABLE marketing_cases
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'published'
CHECK (status IN ('draft', 'pending_sync', 'published', 'archived'));

-- Atualiza todos os registros existentes para 'published' (já é o default, mas garantindo)
UPDATE marketing_cases
SET status = 'published'
WHERE status IS NULL OR status = '';

-- Cria índice para melhorar performance de filtros por status
CREATE INDEX IF NOT EXISTS idx_marketing_cases_status ON marketing_cases(status);

-- Cria índice composto para filtrar cases publicados ativos (usado no mapa)
CREATE INDEX IF NOT EXISTS idx_marketing_cases_published_active 
ON marketing_cases(status, ativo, deletado_em)
WHERE status = 'published' AND ativo = true AND deletado_em IS NULL;

-- Comentário na coluna
COMMENT ON COLUMN marketing_cases.status IS 'Status do case: draft (rascunho local), pending_sync (aguardando sincronização), published (ativo no mapa), archived (arquivado)';
