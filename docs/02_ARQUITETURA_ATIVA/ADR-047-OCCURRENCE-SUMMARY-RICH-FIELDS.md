# ADR-047 — OccurrenceSummary com campos agronômicos ricos

**Status:** ATIVO  
**Data:** Jul/2026  
**Relacionados:** ADR-013 · ADR-024 · ADR-025 · ADR-044 S1/S2 (HTML)

## Contexto

`OcorrenciaSnapshot` (relatorios) e o HTML de visita já suportam campos ricos
(cultivar, estádio, métricas JSON, etc.). O caminho visita → relatório via
`IReportWriter` / `IOccurrenceRead` descartava esses campos: o adapter
mapeava tudo para `null` porque `OccurrenceSummary` só tinha o DTO mínimo.

## Decisão

1. Expandir `OccurrenceSummary` em `core/contracts/i_occurrence_read.dart` com
   campos ricos **nullable** (sem mudar campos existentes obrigatórios).
2. `OccurrenceReadAdapter` mapeia a partir de `Occurrence` do domínio.
3. `ReportWriterAdapter` propaga os campos para `OcorrenciaSnapshot`.

## Não-objetivos

- Não alterar schema SQLite.
- Não unificar `Occurrence` com `OcorrenciaSnapshot`.
- Não inventar valores default para campos ausentes.

## Consequências

- Relatórios gerados ao concluir visita preservam riqueza agronômica no HTML.
- Consumidores que ignoram os novos campos continuam válidos (nullable).
- Qualquer novo campo persistido em ocorrência exige atualizar adapter + DTO
  no mesmo PR (contrato + implementador).
