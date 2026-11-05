# ADR-054 — Relatório de visita: NDVI por talhão e clima manual

**Status:** Aceito  
**Data:** Nov/2026

## Contexto

Relatórios de visita TBDC-inspired devem exibir, por talhão, a mancha NDVI já disponível no app, e opcionalmente previsão/clima manual para os próximos três dias com nota de pulverização — sem API automática de clima.

## Decisão

1. **NDVI:** enriquecimento no `relatorio_visit_html_builder.dart` via contrato `INdviLatestLookup` / `NdviLatestSummary` (ADR-045). O renderer em `core/html_templates/visita_html_renderer.dart` só consome chaves extras no JSON de talhões (`ndviImageSrc`, `ndviCaption`). Proibido importar `modules/ndvi/` a partir de `consultoria/relatorios`.
2. **Imagem:** ordem `greenMaskLocalPath` (arquivo existe) → `localPath` → `imageUrl`, resolvida com `RelatorioHtmlRenderer.resolvePhotoSrcForExport`.
3. **Clima manual:** modelo `RelatorioClimaManual` persistido em SQLite (`relatorios.clima_manual_json`, migração v49). Seção HTML omitida quando `RelatorioClimaManual.hasContent` é falso. Sync Supabase `relatorios_v2` permanece lossy — clima local-only.
4. **NDMI:** não existe no repositório; fora de escopo até contrato dedicado.

## Consequências

- Agrônomo preenche clima na tela de detalhe do relatório (`pendente_revisao`).
- Export HTML offline inclui NDVI inline quando houver arquivo/URL resolvível.
