# Prompt 11 — «Oculto no mapa» no relatório Marketing

**Branch:** `cursor/prompt-11-oculto-mapa-relatorio`  
**Copy (Raudinei):** **Oculto no mapa** — sem ícone; destaque no card (subtitle + chip âmbar).  
**Regra:** case continua `published` na fonte; pin oculto só no mapa (`ocultaPinsMarketingNoMapa`).

## PASSO 0

```bash
rg pinOcultoNoMapa marketing_case_report
rg _marketingReportCard relatorios_marketing_reports
```

## Escopo

- `lib/core/contracts/marketing_case_report_snapshot.dart` — campo `pinOcultoNoMapa`
- `lib/modules/marketing/infra/marketing_case_reports_lookup_adapter.dart` — published + plano expirado/inativo
- `lib/modules/consultoria/relatorios/presentation/relatorios_marketing_reports.dart` — card visível
- `test/modules/marketing/marketing_report_snapshot_pin_oculto_test.dart`

## Validação

`flutter analyze --fatal-infos lib/` · `flutter test test/modules/marketing/marketing_report_snapshot_pin_oculto_test.dart` · `./tool/arch_check.sh`
