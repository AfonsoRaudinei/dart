# PROMPT 03 — AUDITORIA FINAL: DT-025-3 + DT-023-5
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Auditoria Final (READ-ONLY)
**Tipo:** GATE DE QUALIDADE — zero edição — decide commit
**Pré-requisito:** PROMPT 02 executado
**Risco:** Nenhum — apenas leitura e decisão

---

## OBJETIVO

Confirmar que DT-023-5 e DT-025-3 estão de fato resolvidas,
sem regressão em nenhum módulo.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar nenhum arquivo
❌ Não corrigir nada — apenas reportar
❌ Não commitar

---

## PASSO 1 — VERIFICAR IMPORTS ELIMINADOS

```bash
echo "=== lib/ui/ → visitas/ (deve ser VAZIO) ==="
grep -rn "import.*modules/visitas" lib/ui/ --include="*.dart"

echo "=== map/presentation/widgets/ → visitas/ (deve ser VAZIO) ==="
grep -rn "import.*modules/visitas" \
  lib/modules/map/presentation/widgets/ --include="*.dart"
```

---

## PASSO 2 — VERIFICAR CONTAGENS

```bash
wc -l lib/ui/screens/private_map_screen.dart
wc -l lib/ui/components/map/map_bottom_sheet.dart
```

`private_map_screen.dart` deve estar ≤ 900.

---

## PASSO 3 — ARCH_CHECK

```bash
bash tool/arch_check.sh 2>&1
echo "EXIT CODE: $?"
```

---

## PASSO 4 — FLUTTER ANALYZE

```bash
flutter analyze 2>&1 | tail -8
```

---

## PASSO 5 — TESTES

```bash
flutter test test/modules/consultoria/ 2>&1 | tail -3
flutter test test/drawing/ 2>&1 | tail -3
flutter test test/modules/ 2>&1 | tail -5
```

---

## PASSO 6 — TABELA DE DÍVIDAS FINAL

Consolidar o estado de todas as dívidas abertas dos três ciclos:

```
DT-023-5: lib/ui/ → visitas/ direto     → [✅ | ❌]
DT-025-3: visit_active_card → visitas/  → [✅ | ❌]
DT-023-7: VisitSession não @immutable   → ⏳ ADR futuro
DT-023-8: Geofence duplicado            → ⏳ ADR futuro
DT-025-4: Fragmentação lib/ui/map/      → ⏳ Fase 3
DT-025-6: Testes ausentes em map/       → ⏳ próximo ciclo
DT-025-7: map_ui_providers mislocado    → ⏳ ADR futuro
```

---

## RELATÓRIO FINAL

```
══════════════════════════════════════════════════════════
AUDITORIA FINAL — DT-025-3 + DT-023-5
══════════════════════════════════════════════════════════

lib/ui/ sem imports de visitas/:     [✅ | ❌]
map/widgets/ sem imports de visitas/:[✅ | ❌]
private_map_screen ≤ 900 linhas:     [✅ N ln | ❌ N ln]
arch_check.sh Exit 0:                [✅ | ❌]
flutter analyze 0 erros novos:       [✅ | ❌]
Testes sem regressão:                [✅ | ❌]
ADR-023 DT-023-5 resolvida:          [✅ | ❌]
ADR-025 DT-025-3 resolvida:          [✅ | ❌]

RESULTADO: [✅ APROVADO | ❌ BLOQUEADO — <motivo>]
══════════════════════════════════════════════════════════
```

---

## ENCERRAMENTO

Se aprovado → commitar.

Estado pós-commit das dívidas dos 3 ciclos:

**Resolvidas (8 de 15):**
DT-023-1/2/3/4/5/6, DT-025-1/2/3

**Pendentes documentadas (7 de 15):**
DT-023-7/8, DT-025-4/5/6/7/8

Próximo ciclo natural: `DT-025-6` — testes unitários em `map/`.
Ou pausa para build TestFlight — a decisão é sua.
