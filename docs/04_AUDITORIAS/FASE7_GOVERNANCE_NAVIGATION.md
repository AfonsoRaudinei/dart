# Fase 7 — Governança & Navegação

**Meta holística:** 91% · **Pré-requisito:** Fase 6 (sync hardening)

## Objetivo

Eliminar navegação por stack (`context.pop`/`canPop`) e reforçar governança Map-First via CI.

## Entregas

| Item | Arquivo | Descrição |
|---|---|---|
| Rotas agenda L2+ | `AppRoutes.agendaDay` / `agendaEvent` | URLs canônicas declarativas |
| Auth back | `recover_password_page`, `register_page` | `context.go(AppRoutes.login/publicMap)` |
| Agenda detail | `agenda_event_detail_page` | voltar/excluir → `AppRoutes.agendaDay` |
| REGRA-NAV-1 | `tool/arch_check.sh` | FAIL em `context.pop()` / `canPop()` em `lib/` |
| AGENTS ui | `lib/ui/AGENTS.md` | pop permitido só em modais |

## Contrato de navegação

```
L0  /map              → SmartButton ☰ (SideMenu)
L1  /agenda, /settings, … → SmartButton ← go(/map)
L2+ /agenda/day, /agenda/event/:id → go() declarativo (sem pop)
Modais (Dialog/Sheet) → Navigator.pop() legítimo
```

## Rotas agenda (pós Fase 7)

```dart
AppRoutes.agendaDay(DateTime date)  // /agenda/day?date=...
AppRoutes.agendaEvent(String id)    // /agenda/event/:id
```

## Ferramentas

```bash
./tool/arch_check.sh          # REGRA-NAV-1
flutter test test/navigation/
flutter test test/architecture/navigation_fase7_test.dart
```

## Ratchet

- Zero `context.pop()` / `context.canPop()` em `lib/**/*.dart` (exceto comentário smart_button)
- Novas subtelas: helper em `AppRoutes` + `context.go()` / `context.push()`
- Não criar sub-rotas sob `/map`

---

*Fase 7 — Governança & Navegação | Jun/2026*
