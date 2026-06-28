# Guia de Profiling — Fase 0 (DevTools)

**Objetivo:** congelar traces de referência para comparar após Fase 1 (hot paths).  
**Ferramenta:** Flutter DevTools → Performance + CPU Profiler  
**Dispositivo recomendado:** físico mid-range (Android) ou iPhone SE — não emulador x86.

---

## Pré-requisitos

```bash
flutter run --profile -d <device_id>
# Abrir DevTools URL exibida no terminal
```

Salvar traces em: `docs/04_AUDITORIAS/traces/fase0/` (não versionar `.json` grandes — usar artifact local ou CI manual).

---

## Cenário 1 — Map pan/zoom (60 s)

**Hipótese:** `MapBuildOrchestrator` com 21× `ref.watch` causa rebuild cascade durante pan.

| Passo | Ação |
|---|---|
| 1 | Login → `/map` privado com talhões visíveis |
| 2 | DevTools → Performance → Record |
| 3 | Pan contínuo 20 s + pinch zoom 20 s + pan 20 s |
| 4 | Stop → exportar timeline |

**Métricas a registrar:**

| Métrica | Baseline Fase 0 (preencher) |
|---|---|
| Frame budget >16 ms (%) | ___ |
| Jank frames (count) | ___ |
| `MapBuildOrchestrator.build` calls/s | ___ |
| Raster time médio (ms) | ___ |

**Critério Fase 1:** reduzir frames >16 ms em ≥20% vs este baseline.

---

## Cenário 2 — Drawing vertex drag (45 s)

**Hipótese:** `DrawingController.notifyListeners` (44 call sites) gera jank em edição de vértice.

| Passo | Ação |
|---|---|
| 1 | Abrir drawing mode, polígono com ≥6 vértices |
| 2 | Record Performance |
| 3 | Arrastar 1 vértice por 15 s (movimento lento) |
| 4 | Arrastar rapidamente 15 s |
| 5 | Adicionar 3 vértices via tap 15 s |
| 6 | Stop → exportar |

**Métricas:**

| Métrica | Baseline Fase 0 |
|---|---|
| notifyListeners/s durante drag | ___ |
| Frame p95 (ms) | ___ |
| `DrawingEditLayer` rebuild count | ___ |

**Critério Fase 1:** p95 frame ≤ 20 ms durante drag lento.

---

## Cenário 3 — Sync trigger pós-reconexão (30 s)

**Hipótese:** sync serial de 5 módulos bloqueia UI thread indiretamente via providers.

| Passo | Ação |
|---|---|
| 1 | Modo avião ON por 10 s (app aberto no mapa) |
| 2 | Modo avião OFF |
| 3 | Record Performance + CPU Profiler |
| 4 | Aguardar conclusão sync (SyncOrchestrator) |
| 5 | Stop |

**Métricas:**

| Métrica | Baseline Fase 0 |
|---|---|
| Tempo total sync (s) | ___ |
| Módulos executados (ordem) | Tier 0: Agronomic → Tier 1 paralelo: Drawing, Occurrence, Visit, Agenda |
| UI jank durante sync (frames >16 ms) | ___ |
| Pico CPU main isolate (%) | ___ |

**Critério Fase 6:** sync paralelo independente — meta −40% tempo total.

---

## Snapshot automatizado (CI/local)

Métricas estáticas correlacionadas — executar antes/depois de cada fase:

```bash
./tool/perf_baseline.sh
flutter test --coverage
./tool/coverage_by_module.sh
```

---

## Template de registro (copiar por cenário)

```markdown
### Trace YYYY-MM-DD — Cenário N
- Device: 
- Flutter: 
- Commit: 
- Frame p95: 
- Jank count: 
- Observações: 
```

---

*Fase 0 — Baseline & Instrumentação | Jun/2026*
