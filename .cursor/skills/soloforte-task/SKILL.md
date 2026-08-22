---
name: soloforte-task
description: Executa tarefas no SoloForte Flutter seguindo Map-First, bounded contexts e arch_check. Use ao implementar features, corrigir bugs, criar providers ou editar módulos consultoria/agenda/map/drawing/produtor, ou quando o usuário mencionar SoloForte, ADR, arch_check ou bounded context.
---

# SoloForte — Execução de Tarefa

**Fonte da verdade:** [AGENTS.md](../../AGENTS.md)

## Fluxo obrigatório

### 1. Descoberta (PASSO 0)

```bash
find lib/ -name "arquivo_alvo.dart"
rg -l "NomeClasse" lib/
```

Identificar módulo, contratos e testes em `test/modules/<modulo>/`.

### 2. Declaração (antes de codar)

```
Módulo:       lib/modules/<nome>/
Bounded ctx:  <core|map|drawing|agenda|consultoria|...>
Objetivo:     <1 frase>
Arquivos:     <lista fechada>
Contrato:     altera? sim/não
Fronteira:    altera? sim/não → se sim, ADR necessário
```

### 3. Implementação

- Riverpod: `@riverpod` — nunca StateNotifier novo
- Navegação: `context.go('/map')` para retorno; rotas em `app_routes.dart`
- Persistência: `user_id` + `sync_status`; schema SQLite v41
- Sheets: `lib/core/ui/sheets/soloforte_sheet.dart`
- Scroll com FAB: `kFabSafeArea = 76dp`
- **Se tocar sheets:** `rg showSoloForteSheet` + `rg 'backgroundColor: Colors.transparent'` (REGRA-SHEET-BLAST-1)
- **Se tocar map chrome:** `kMapActionColumnBottomInset` — nunca `mapSheetChromeInsetProvider` (REGRA-MAP-CHROME-1)
- **Host UI do mapa:** `lib/ui/screens/map/` + `lib/ui/components/map/` (política 4A) — `modules/map/` é só adapters/providers leves

### 4. Validação

```bash
flutter pub run build_runner build --delete-conflicting-outputs  # se @riverpod novo
flutter analyze lib/modules/<modulo>/
flutter test test/modules/<modulo>/
flutter test test/regression/sheets/soloforte_sheet_contract_test.dart  # se tocou sheets
flutter test test/regression/map/controls_overlay_regression_test.dart  # se tocou map chrome
./tool/arch_check.sh
```

### 5. Checklist final

```
[ ] Apenas módulo declarado alterado?
[ ] arch_check.sh → Exit 0?
[ ] Testes afetados passando?
[ ] Navegação Map-First intacta?
[ ] Sem dados fictícios?
[ ] Branch pushed — sem merge na main? (merge é do supervisor)
```

Quem mergeia é o **supervisor** (`gh pr merge --auto --rebase` após o revisor). Este fluxo **não** faz `git push origin main`.

## Contratos principais

Ver tabela completa em [AGENTS.md](../../AGENTS.md). Resumo:

| Contrato | ADR | Consumidores |
|---|---|---|
| `IClientLookup` | 015 | drawing, agenda, marketing, visitas |
| `IFarmLookup` | — | drawing, ndvi, marketing |
| `IFieldLookup` | 022 | drawing, ndvi |
| `IVisitSessionLookup` | 020 | agenda, consultoria |
| `IReportWriter` | 013 | visitas |
| `IDrawingFieldWriter` | 038 | consultoria (adapter) |
| `IProducerInviteWriter` | 039 | produtor |
| `IProducerPropertyGateway` | 040 | produtor |
| `IOccurrenceAccessReader` | 041 | produtor/map |

## Módulos deletados

- `lib/modules/reports/` → `lib/modules/consultoria/relatorios/`
- `lib/modules/consultoria/agenda/` → `lib/modules/agenda/`
- `lib/modules/relatorios/` (top-level) → **não existe**

## Referências

- ADRs: [docs/02_ARQUITETURA_ATIVA/](../../docs/02_ARQUITETURA_ATIVA/)
- Prompts: [prompt/](../../prompt/)
- Auditoria IPA 210: [.agent/AUDITORIA_REGRESSAO_IPA210.md](../../.agent/AUDITORIA_REGRESSAO_IPA210.md)
- Dev iOS Wi-Fi: `./run_dev.sh` (`.env.local`)
