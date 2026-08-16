# Checklist — Sheets Marketing / Ocorrências (mapa) — 100%

**Data:** 15/Ago/2026  
**Status:** **100% design Azul** (código) · smoke QA dispositivo pendente  
**SHA entrega:** `be38273` (`origin/main`) · commits `8491329` (ocorrências) · `12213f9` (marketing)

---

## Escopo concluído

| # | Superfície | % | Notas |
|---|---|---|---|
| 1 | Marketing pin → `MarketingCaseSheet` | 100 | preserve DSS + `themeId` |
| 2 | Ocorrência pin → `OccurrenceDetailSheet` | 100 | |
| 3 | Criar ocorrência → `OccurrenceCreationSheet` | 100 | residuals white só em `!isIos` |
| 4 | Lista → `OccurrenceListSheet` + filtros | 100 | cards/filtros iOS |
| 5 | Cliente selector no form | 100 | `occurrenceFormIsIos` |
| 6 | Marketing create (`novo_case_*`, avaliacao, foto, roi, conclusao) | 100 | |

## Preserve intencionais

- `map_sheet_controller.dart`
- `marketing_case_sheet.dart`

## Gates

```bash
./tool/arch_check.sh
flutter test test/regression/sheets/soloforte_sheet_contract_test.dart
rg -n "preserveMaterialDefaults: true" lib --glob '*.dart'
```

## QA dispositivo (Mac)

```bash
git fetch origin && git checkout main && git pull origin main
flutter pub get
# rebuild IPA / flutter run — hot restart não basta
```

*Fase 3b backlog pin+create · 15/08/2026*
