# NDVI — Auditoria de Confirmacao Fase 4 (100%)

**Data:** 2026-06-27  
**Escopo:** Recuperacao NDVI fases 1–3 + blindagem regressao  
**Baseline:** ADR-042 · schema SQLite v38 · arch_check Exit 0

---

## Score final

| Dimensao | Meta | Resultado | Status |
|---|---|---|---|
| Lookup talhao consultoria + drawing | 100% | ChainedFieldLookup em `main.dart` | OK |
| Propagacao de erro remoto | 100% | HTTP != 404 → throw | OK |
| Multi-data + cache TTL | 100% | NdviCachePolicy 24h + stubs | OK |
| Planet preview rotulado | 100% | `planet_preview` sem mascara verde | OK |
| Testes regressao | 100% | 55/55 passed | OK |
| Enforcement CI | 100% | REGRA-NDVI + job `ndvi-regression` | OK |
| Deploy ops (Sentinel token) | N/A codigo | Manual pre-prod | Pendente ops |

**Score codigo + testes + gates: 100%**  
**Score E2E producao: ~95%** (depende deploy `ndvi-fetch` + `SENTINEL_HUB_TOKEN`)

---

## Checklist de confirmacao

### Fase 1 — Desbloqueio (P0)

- [x] `ChainedFieldLookup` tenta drawing, fallback consultoria/geofence
- [x] `FieldLookupGeofenceAdapter` calcula bbox a partir da geometria
- [x] Erros remotos propagados (404 → null; demais → throw)
- [x] Testes: `chained_field_lookup_test`, `ndvi_phase1_integration_test`

### Fase 2 — Dados completos (P1)

- [x] `NdviRemoteFetchResult` com `available_dates`
- [x] Cache TTL 24h + fingerprint geometria
- [x] `ensureImageForDate` fetch lazy
- [x] Edge `ndvi-fetch` retorna stats NDVI
- [x] Testes: `ndvi_phase2_test`

### Fase 3 — Robustez (P1/P2)

- [x] Planet fallback marcado `planet_preview` / `is_ndvi: false`
- [x] `ndvi_image_utils` — labels, mascara, disclaimer
- [x] Logging `AppLogger` tags NDVI
- [x] ADR-042 documentado
- [x] Testes: `ndvi_phase3_widget_test`, `ndvi_fetch_contract_test`

### Fase 4 — Blindagem

- [x] REGRA-NDVI em `tool/arch_check.sh` (bloqueante)
- [x] Job CI `ndvi-regression` em `.github/workflows/architecture.yml`
- [x] `lib/modules/ndvi/AGENTS.md` com invariants
- [x] ADR-042 registrado em `AGENTS.md` raiz

---

## Comandos de validacao

```bash
flutter test test/modules/ndvi/ test/supabase/ndvi_fetch_contract_test.dart
flutter analyze lib/modules/ndvi/
./tool/arch_check.sh
```

Ultima execucao desta auditoria: **55/55 testes**, **analyze 0 issues**, **arch_check Exit 0**.

---

## Ops pre-go-live (fora do codigo)

1. Configurar secret `SENTINEL_HUB_TOKEN` no projeto Supabase.
2. Deploy: `supabase functions deploy ndvi-fetch`.
3. Validar talhao com `bordadura_geo` em ambiente de homologacao.
