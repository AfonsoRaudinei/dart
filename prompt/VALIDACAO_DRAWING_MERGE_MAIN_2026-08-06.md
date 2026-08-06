# Validação Drawing → Merge main — 2026-08-06

## Sync MacBook (Fase 2)

```bash
git fetch origin
git checkout main
git pull origin main
flutter pub get
```

| Item | Valor |
|---|---|
| Branch | `main` |
| SHA local | `4dfa3986e64a85d6355245b60292705dcbcb876a` |
| SHA remoto (`origin/main`) | `4dfa3986e64a85d6355245b60292705dcbcb876a` |
| Working tree | limpa |
| Alinhamento | **OK — local == remote** |

## PRs integrados nesta entrega

| PR | Escopo | Status |
|---|---|---|
| #25 | Drawing bottom bar layout | Mergeado em main |
| #26 | Remoção gate `drawing_v1` no draw sheet | Mergeado em main |
| #27 | Gesture guard (`suppressesMapContextTaps`) | Mergeado em main |
| #28 | Store preflight PrivacyInfo + SCHEDULE_EXACT_ALARM | Mergeado em main |

## Gates

| Gate | Resultado |
|---|---|
| `./tool/arch_check.sh` | Exit 0 (pré-merge) |
| `flutter analyze lib/` | 0 issues (pré-merge) |
| `flutter test` | 1198 passed, 1 skipped (pré-merge) |
| Device QA | **Simulador OK** (Opção B) |
| Device físico | Pendente — gate TestFlight / pré-Transporter |

## Critérios de regressão confirmados no simulador

- 4.1 — tap talhão fora do drawing → SnackBar (não sheet)
- 4.2 — long press fora do drawing → modal marketing/case

## Próximos passos (loja)

1. Smoke físico USB (6 passos) quando device disponível
2. `./tool/release_store_check.sh`
3. `./build_testflight.sh` → validar IPA → Transporter
4. Play Console: declarar Alarms & reminders (`docs/android/SCHEDULE_EXACT_ALARM_PLAY_CONSOLE.md`)
