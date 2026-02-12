# Changelog

Todas as tags e marcos técnicos notáveis deste projeto serão documentados aqui.

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
