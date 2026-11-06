# ADR-056 — Ordem de aplicação em três campos

**Data:** 05/11/2026  
**Status:** APROVADO  
**Módulos:** `consultoria/occurrences/`, `core/contracts/`, `core/html_templates/`, `core/database/`

## Contexto

A ocorrência guardava a recomendação num único texto livre (`recomendacoes`).
O produtor recebe o relatório HTML pelo mesmo link público de hoje e precisa
ler, no celular, três informações separadas no padrão TBDC de ordem de
aplicação: o que fazer, a dose e quando aplicar. Catálogo de produtos e
estoque ficam fora.

## Decisão

1. **SQLite v49** — colunas nullable em `occurrences`:
   `recomendacao_acao`, `recomendacao_dose`, `recomendacao_quando`.
2. **Legado** — `recomendacoes` permanece. Na gravação, se algum dos três
   campos tem texto, o app reescreve `recomendacoes` com linhas rotuladas
   (`O que fazer` / `Dose` / `Quando`). Na leitura, se os três estão vazios
   e o legado tem texto, a UI e o HTML mostram esse texto só como ação.
   O texto antigo não é repartido.
3. **Contrato** — `OccurrenceSummary` e `OcorrenciaSnapshot` ganham os três
   campos nullable. `IOccurrenceRead` e `IReportWriter` propagam o valor.
   Sync Supabase envia as três colunas e o espelho legado
   (`20261105233000_occurrences_recomendacao_ordem.sql`, idempotente).
4. **HTML** — seção “Ordem de aplicação” com até três `.sf-row` em
   `ocorrencia_detalhada` e no bloco de ocorrência do relatório de visita.
   No celular as linhas empilham rótulo e valor para o produtor copiar.
5. **Regra única** — `lib/core/domain/occurrence_recomendacao_ordem.dart`.
   `core/` não importa `modules/`.

## Não-objetivos

- Inventário, catálogo de produtos ou integração Farmbox.
- Apagar a coluna `recomendacoes`.
- Parser do texto livre antigo em dose e janela.

## Consequências

- Leitores que só conhecem `recomendacoes` continuam vendo a ordem formatada.
- Ocorrências antigas aparecem como “O que fazer” até o consultor salvar de novo.
- A migration Supabase precisa estar aplicada no projeto live antes do push
  das três colunas; sem ela o upsert remoto falha.
