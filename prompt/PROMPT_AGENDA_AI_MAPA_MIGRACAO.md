# PROMPT — Migração do AgendaAI: da Agenda para o Mapa

**Status:** CONCLUÍDO (baseline auditado em 06/07/2026)  
**Módulos:** `agenda_ai` + `map` (overlay em `private_map_screen`)  
**Risco:** MÉDIO — dois bounded contexts; acoplamento apenas via contratos existentes

---

## PASSO 0 — Resultado da auditoria

### Arquivos `agenda_ai`

| Arquivo | Função |
|---|---|
| `lib/modules/agenda_ai/presentation/widgets/agenda_ai_sheet.dart` | Sheet do agente (`showAgendaAiSheet` + `_AgendaAiSheet`) |
| `lib/modules/agenda_ai/infra/agenda_ai_launcher_adapter.dart` | `IAgendaAiLauncher` → abre sheet |
| `lib/modules/agenda_ai/data/services/agenda_ai_service.dart` | Serviço Supabase |

### Asset

- `assets/ia.png` — presente

### Referências `ia.png` no código

| Arquivo | Papel |
|---|---|
| `lib/ui/components/map/widgets/map_agenda_ai_button.dart` | **Único** uso de `ia.png` |

### Ponto de entrada no mapa

```
private_map_screen.dart
  └── map_build_orchestrator.dart
        └── MapControlsOverlay (map_controls_overlay.dart)
              └── MapAgendaAiButton → IAgendaAiLauncher → AgendaAiSheet
```

> `private_map_sheets.dart` **não existe** — sheet registrada via `showAgendaAiSheet()` + `showSoloForteSheet`.

### Contratos utilizados

| Contrato | Provider | Registrado em `main.dart` |
|---|---|---|
| `IAgendaAiLauncher` | `agendaAiLauncherProvider` | ✅ `AgendaAiLauncherAdapter` |
| `IAgendaAiRecommendationContextLookup` | `agendaAiRecommendationContextLookupProvider` | ✅ `AgendaAiRecommendationContextAdapter` |
| `IAgendaAiVisitWriter` | `agendaAiVisitWriterProvider` | ✅ `AgendaAiVisitWriterAdapter` |
| `IOpportunityLookup` | via adapter de contexto | ✅ (carteira → contrato) |
| `IAgendaSessionBridge` | `agendaSessionBridgeProvider` | ✅ (visitas/agenda) |
| `IAgendaObservable` | `iAgendaObservableProvider` | ✅ (map observer) |

### Carteira

```bash
rg "ia\.png|AgendaAi" lib/modules/carteira/
# → LIMPO (zero matches)
```

### Agenda (módulo legado de calendário)

- Sem ícone `ia.png` nem entry point de UI do agente
- Apenas adapters de escrita (`AgendaAiVisitWriterAdapter`)

### Baseline CI

- `./tool/arch_check.sh` → Exit 0
- `flutter analyze lib/` → sem erros novos nos arquivos do escopo
- `flutter test test/ui/components/map/map_agenda_ai_button_test.dart` → passa

---

## Decisão arquitetural (implementada)

> O agente de visitas vive **exclusivamente no mapa** (`/map`).  
> Um único ícone `ia.png` — overlay em `MapControlsOverlay`, **não** FAB.  
> Carteira e oportunidades são consumidas **dentro** do agente via contratos.

---

## Implementação atual

### Overlay no mapa

**Arquivo:** `lib/ui/components/map/widgets/map_agenda_ai_button.dart`

- `Image.asset('assets/ia.png')` — 44×44 dp
- `Tooltip`: `"Agente de Visitas"`
- Feature flag `agenda_ai_v1` — oculto quando desabilitado
- GPS opcional via `AgendaAiLaunchContext`

**Posição:** `MapControlsOverlay` — `right: 16`, `bottom: kFabSafeArea + safeBottom + 200`

### Abertura da sheet

**Arquivo:** `lib/modules/agenda_ai/presentation/widgets/agenda_ai_sheet.dart`

- Wrapper: `showSoloForteSheet` (ADR-027)
- Consome `IAgendaAiRecommendationContextLookup` e `IAgendaAiVisitWriter`
- Agendamento via contrato (sem import direto de `agenda/`)

### Fluxo

```
Tap ia.png
  → agendaAiLauncherProvider.showSheet(context, launchContext)
  → AgendaAiLauncherAdapter
  → showAgendaAiSheet(context)
  → _AgendaAiSheet (SoloForteSheet)
```

---

## Escopo — o que NÃO foi alterado

- ❌ `smart_button.dart`
- ❌ `app_router.dart` (sem rotas novas)
- ❌ Contratos em `core/contracts/`
- ❌ Lógica interna de `agenda/` use cases
- ❌ Tema / Design System

---

## Checklist de validação

```
[x] F1 — arch_check.sh → Exit 0
[x] F2 — flutter analyze sem erros novos no escopo
[x] F2b — zero ia.png / AgendaAi em carteira/
[x] F2c — único ia.png → map_agenda_ai_button.dart
[x] F3 — testes map_agenda_ai_button passando
[x] F4 — outros módulos não alterados (exceto alinhamento tooltip/tamanho)
[x] F5 — navegação inalterada
[x] F6 — tema inalterado
[x] F7 — contratos inalterados
[x] F8 — SmartButton inalterado
[x] F9 — entry point exclusivo no mapa
```

---

## Encerramento

O módulo `agenda_ai` tem ponto de entrada **único** no mapa via `MapAgendaAiButton`.  
Nenhuma rota nova. Nenhum contrato alterado.  
Carteira e agenda não expõem ícone do agente.
