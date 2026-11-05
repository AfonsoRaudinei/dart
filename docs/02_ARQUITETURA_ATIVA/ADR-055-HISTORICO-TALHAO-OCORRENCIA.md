# ADR-055 — Histórico factual do talhão na ocorrência

**Status:** ATIVO  
**Data:** Nov/2026  
**Relacionados:** ADR-014 · ADR-047

## Contexto

O HTML de ocorrência detalhada mostra o registro atual. O mesmo problema
pode ter voltado no mesmo talhão em safras anteriores, e essa recorrência
já está nas ocorrências locais do cliente. Não é feed, comentário nem nome
de produtor.

## Decisão

1. Agregado somente leitura em
   `occurrences/domain/occurrence_historico_talhao.dart`.
2. A linha entra no HTML (`historico_talhao_linha`, classe `sf-caption`)
   só quando há **2 ou mais** ocorrências do mesmo cliente, no mesmo talhão,
   com a mesma chave de praga.
3. Chave: `description` normalizada (trim, minúsculas, espaços colapsados).
   Se vazia, a nota da categoria ativa em `notasCategoriasJson`. Sem chave,
   sem linha.
4. Fora do agregado: `area_visitada`, `amostra_solo` e registros apagados
   (`deleted` / `deleted_local` / `deleted_at`).
5. Talhão: `occurrences.field_id` (SQLite **v49**, nullable) quando a criação
   veio de `OccurrenceTalhaoPrefill`. Linha antiga sem coluna usa o polígono
   de `IFieldLookup.findById`. `field_id` preenchido e diferente exclui o
   ponto, mesmo dentro da geometria.
6. A cópia cita o estádio da ocorrência mais recente (`estadioFenologico`).
   Sem estádio, a data `DD/MM/AAAA`.
7. `field_id` **não** entra no payload remoto. O pull preserva o valor local
   no `INSERT OR REPLACE`.

## Não-objetivos

- NDMI, feed, comentários, nomes de produtores.
- Sincronizar `field_id` com o Supabase.
- Alterar `OccurrenceSummary` / `IReportWriter` (ADR-047).
