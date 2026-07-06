# Changelog

Todas as tags e marcos técnicos notáveis deste projeto serão documentados aqui.

---

## release/v1.1 — build 151 (2026-07-06)

### Agente IA no mapa (estratégia semanal de visitas)
- Ícone `assets/ia.png` **somente no mapa** (`MapAgendaAiButton`)
- Removido da Agenda (`agenda_month_page.dart`)
- GPS enriquecido via `AgendaAiLaunchContext` no payload da Edge Function
- Agendamento de visitas via `IAgendaAiVisitWriter`
- Fix IPA: `APP_VERSION` real na feature flag + fallback quando backend de flags indisponível
- Fix build: `kMapTilerApiKey` em `MapConfig` (sem `map_secrets.dart` gitignored)
- Fix sync: `syncTier` explícito em todos os módulos

---

## draw-stable-v1
**Data:** 2026-02-11  
**Branch:** `release/v1.1`

### Resumo
Baseline estável do módulo Drawing após hardening completo RT-DRAW-01 → RT-DRAW-12a.

### Conquistas
- Pipeline RT-DRAW-01 → RT-DRAW-12a concluído
- 103/103 testes passando (unit, widget, regressão)
- 0 warnings / 0 erros / 0 skip / 0 flaky
- `flutter analyze`: No issues found
- Lifecycle e race conditions corrigidos
- Performance hardening aplicado (cache, BBox, sampling)
- Auditoria técnica e UX concluídas

### Correções Críticas Aplicadas
- **Memory Leak (Timer):** `dispose()` com `_isDisposed` guard + `_validationDebounce?.cancel()`
- **Memory Leak (Overlay):** Try-catch em `_removeTooltip()`
- **Race Condition:** Guard `_isDisposed` em `loadFeatures()`, `selectTool()`, `appendDrawingPoint()`, `cancelOperation()`, `syncFeatures()`
- **Dispose Idempotente:** Múltiplos `dispose()` não lançam erro
- **Cancel Limpa Pontos:** `cancelOperation()` agora limpa `_currentPoints`

### Performance
- Cache em `DrawingLayerWidget`: 75% mais rápido (160ms → 40ms)
- BBox check antes de validação: 90% mais rápido (500ms → 50ms)
- Sampling para polígonos complexos: 87% mais rápido (800ms → 100ms)

### Code Quality
- Código duplicado eliminado (40 linhas → método unificado `calculateGeometryArea`)
- Error handling específico (TimeoutException, SocketException)
- Dartdoc em APIs públicas
- 103 testes cobrindo unit, widget, state machine, regressão e concorrência

### Regra de Governança
- ❌ Nenhuma alteração estrutural no Drawing sem nova branch + novos testes + nova tag incremental
- ❌ Tag imutável — nunca reusar, nunca sobrescrever

---

## [1.1.0] - 2026-05-18

### Added
- MapTiler Outdoor v2 integration
- Marker filtering by user plan tier
- REGRA-CROSS-MODULE-2 (warning-only enforcement)
- 17 bounded contexts fully documented

### Fixed
- Centralized bottom sheet wrapper (ADR-027)
- HTML doc comments escaped in map config area
- Drawing tests stabilized with Supabase initialization mock

### Documentation
- ADR-035: DT-035 ui→marketing debt
- ADR-036: bypass REGRA-SHEET-1 (temporary v1.1)
- bounded_contexts.md updated with dependency matrix

### Technical Debt
- DT-025-3: map → visitas (planned v1.2)
- DT-028: showRadarProvider → MapContext.clima (planned v1.2)
- DT-035: ui → marketing (planned v1.2)
- Bypass REGRA-SHEET-1 (removal planned v1.2)

### Metrics
- flutter analyze: 52 issues
- flutter test: 645 passed, 1 skipped
- arch_check.sh: EXIT 0 (warnings documented)
- 11 structured commits for baseline closure
