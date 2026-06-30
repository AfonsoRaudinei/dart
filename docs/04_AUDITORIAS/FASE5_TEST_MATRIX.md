# Fase 5 — Matriz de Testes por Setor

**Meta holística:** 90% · **Baseline global:** 43,22% (Jun/2026) · **Gate CI:** 36,46%

## Prioridades

| Setor | Prioridade | Lib files | Testes mínimos | Piso coverage |
|---|---|---:|---:|---:|
| `modules/consultoria` | P0 | ~99 | 15 `*_test.dart` | 35% |
| `modules/marketing` | P0 | — | 2 | 25% |
| `modules/carteira` | P0 | — | 3 | 70% |
| `modules/public` | P1 | 7 | 1 | 15% |

## Ferramentas

```bash
flutter test --coverage
./tool/coverage_by_module.sh          # relatório por bounded context
./tool/test_matrix_gate.sh            # matriz Fase 5 (warning-only)
STRICT=1 ./tool/test_matrix_gate.sh   # falha em regressão
./tool/coverage_gate.sh               # gate global CI
```

## Entregas Fase 5 (bootstrap)

- Fix path bucketing em `coverage_by_module.sh` (`lib/modules/` sem barra inicial)
- `tool/test_matrix_gate.sh` — presença + piso por setor
- CI job `coverage` executa matriz (warning-only)
- Novos testes unitários:
  - `test/modules/carteira/` — `categoria_global`, `unidade_categoria`, `opportunity_summary`
  - `test/modules/marketing/domain/marketing_case_test.dart`
  - `test/modules/consultoria/occurrences/domain/occurrence_domain_test.dart`
  - `test/modules/public/public_location_state_test.dart`
- Removido placeholder vazio de marketing

## Próximos incrementos (contínuo)

1. **Consultoria:** `client.dart` serialização, `publicacao_tecnica` round-trip
2. **Marketing:** regras de visibilidade por plano (ADR-011) com fakes
3. **Public:** provider tests com mocks de Geolocator
4. **Map:** setor com 2,3% — visit_completion_observer + providers

## Ratchet

- Não reduzir contagem de testes por setor P0
- Não reduzir coverage de setor abaixo do piso congelado
- Global: manter ≥ 36,46%; alvo incremental +0,5 pp por sprint até 55%
