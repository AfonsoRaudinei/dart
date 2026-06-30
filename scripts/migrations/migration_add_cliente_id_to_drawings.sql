-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRAÇÃO: Adicionar coluna cliente_id na tabela drawing_features
-- ═══════════════════════════════════════════════════════════════════════════
-- Data: 2026-02-11
-- Versão: v1.1.1
-- Descrição: Adiciona suporte para vincular desenhos diretamente a clientes
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Adicionar coluna cliente_id
ALTER TABLE drawing_features 
ADD COLUMN cliente_id TEXT;

-- 2. Criar índice para melhorar performance de consultas por cliente
CREATE INDEX IF NOT EXISTS idx_drawing_features_cliente_id 
ON drawing_features(cliente_id);

-- 3. (Opcional) Popular cliente_id baseado em fazenda_id existente
-- Descomente se quiser migrar dados existentes:
/*
UPDATE drawing_features
SET cliente_id = (
    SELECT cliente_id 
    FROM farms 
    WHERE farms.id = drawing_features.fazenda_id
)
WHERE fazenda_id IS NOT NULL;
*/

-- 4. Verificar resultado
SELECT 
    COUNT(*) as total_features,
    COUNT(cliente_id) as features_with_cliente,
    COUNT(fazenda_id) as features_with_fazenda
FROM drawing_features;
