# PROMPT 06 — AUDITORIA FINAL: Conformidade do módulo `visitas/`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Auditoria Final (READ-ONLY)
**Tipo:** GATE DE QUALIDADE — zero edição — decide se pode commitar
**Pré-requisito:** PROMPTS 02 a 05 executados
**Risco:** Nenhum — apenas leitura e decisão

---

## OBJETIVO

Confirmar que todos os objetivos do ciclo de blindagem de `visitas/` foram
atingidos, que nenhuma regressão foi introduzida, e emitir o veredito
final: APROVADO PARA COMMIT ou BLOQUEADO.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar nenhum arquivo
❌ Não corrigir nada encontrado — apenas reportar
❌ Não commitar

---

## PASSO 0 — CHECKLIST DE ARTEFATOS CRIADOS/ALTERADOS

```bash
# Documentação
find docs/02_ARQUITETURA_ATIVA/ -name "ADR-023*"

# Contrato expandido
cat lib/core/contracts/i_visit_session_lookup.dart | grep -E "class|Future|bool"

# Adapter atualizado
cat lib/modules/visitas/infra/visit_session_lookup_adapter.dart | grep -E "override|_toSummary"

# Novas regras no CI
grep -n "REGRA-VISITAS" tool/arch_check.sh
```

Esperado:
- ADR-023 existe ✅
- `VisitSessionSummary` tem 7 campos e `IVisitSessionLookup` tem 2 métodos ✅
- Adapter tem `findById` e `_toSummary` com 7 campos ✅
- 3 linhas `REGRA-VISITAS` no arch_check.sh ✅

---

## PASSO 1 — VERIFICAR VIOLAÇÕES ELIMINADAS

```bash
echo "=== visit_controller.dart — imports proibidos ==="
grep -n "import.*modules/consultoria\|import.*modules/drawing\|import.*agenda.*presentation" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart

echo "=== geofence_controller.dart — imports proibidos ==="
grep -n "import.*modules/consultoria\|import.*modules/drawing" \
  lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

Resultado esperado: **ambos vazios**.

Se qualquer linha retornar → **BLOQUEADO — DT-023-3 ou DT-023-4 ainda ativa**.

---

## PASSO 2 — VERIFICAR CONTRATO NEUTRO

```bash
grep "import.*modules" lib/core/contracts/i_visit_session_lookup.dart
```

Resultado esperado: **vazio** — a interface não importa módulos.

```bash
cat lib/core/contracts/i_visit_session_lookup.dart
```

Verificar campos do DTO:
- [ ] `id: String` ✅
- [ ] `producerId: String` ✅
- [ ] `status: String` ✅
- [ ] `startTime: DateTime` ✅
- [ ] `areaId: String?` ✅
- [ ] `activityType: String?` ✅
- [ ] `endTime: DateTime?` ✅
- [ ] `isActive` getter ✅
- [ ] `getActiveSession()` ✅
- [ ] `findById(String)` ✅

---

## PASSO 3 — VERIFICAR CONSUMIDORES EXISTENTES NÃO QUEBRARAM

```bash
echo "=== Consumidores via contrato (devem seguir usando o contrato) ==="
grep -rn "visitSessionLookupProvider\|IVisitSessionLookup\|VisitSessionSummary" \
  lib/modules/consultoria/ --include="*.dart"
grep -rn "visitSessionLookupProvider\|IVisitSessionLookup\|VisitSessionSummary" \
  lib/modules/map/ --include="*.dart"
```

Confirmar que os consumidores do ADR-020 (`occurrence_controller`,
`occurrence_list_sheet`) continuam usando `visitSessionLookupProvider` —
não foram afetados pela expansão do DTO.

---

## PASSO 4 — ARCH_CHECK COM NOVAS REGRAS

```bash
bash tool/arch_check.sh 2>&1
echo "EXIT CODE: $?"
```

Resultado esperado:
- Exit 0
- Nenhuma `REGRA-VISITAS` disparando erro
- 3 violações pré-existentes autorizadas listadas sem bloqueio (baseline)
- Nenhuma violação nova

---

## PASSO 5 — FLUTTER ANALYZE

```bash
flutter analyze lib/modules/visitas/ 2>&1 | tail -5
flutter analyze lib/modules/map/ 2>&1 | tail -5
flutter analyze lib/modules/consultoria/ 2>&1 | tail -5
flutter analyze lib/modules/agenda/ 2>&1 | tail -5
```

Resultado esperado em todos: 0 erros novos.

---

## PASSO 6 — TESTES

```bash
flutter test test/consultoria/ 2>&1 | tail -5
flutter test test/drawing/ 2>&1 | tail -5
```

Esperado:
- `consultoria/`: 67/67 ✅
- `drawing/`: 268/268 ✅

---

## PASSO 7 — COMPARAR COM BASELINE DO PROMPT 01

| Item | ANTES (PROMPT 01) | DEPOIS (esperado) | Status |
|---|---|---|---|
| `VisitSessionSummary` campos | 2 (id, status) | 7 campos | ? |
| `IVisitSessionLookup` métodos | 1 (getActiveSession) | 2 (+findById) | ? |
| `visit_controller` imports consultoria | 3 diretos ❌ | 0 | ? |
| `geofence_controller` imports consultoria | 3 diretos ❌ | 0 | ? |
| ADR-023 | AUSENTE | CRIADO | ? |
| REGRA-VISITAS no CI | AUSENTE | 3 regras | ? |
| `arch_check.sh` ponto cego | ATIVO | FECHADO | ? |

Preencher a coluna Status com ✅ ou ❌ para cada item.

---

## RELATÓRIO FINAL

```
══════════════════════════════════════════════════════════
AUDITORIA FINAL — módulo visitas/ — GATE DE QUALIDADE
══════════════════════════════════════════════════════════

ADR-023 criado:                  [✅ SIM | ❌ NÃO]
DTO expandido (7 campos):        [✅ SIM | ❌ NÃO | ⚠️ PARCIAL]
findById() implementado:         [✅ SIM | ❌ NÃO]
DT-023-3 resolvida:              [✅ SIM | ❌ PENDENTE | ⚠️ PARCIAL]
DT-023-4 resolvida:              [✅ SIM | ❌ PENDENTE | ⚠️ PARCIAL]
DT-023-6 (ponto cego CI):        [✅ SIM | ❌ PENDENTE]
Consumidores ADR-020 intactos:   [✅ SIM | ❌ QUEBRADO]
arch_check.sh Exit 0:            [✅ SIM | ❌ EXIT 1]
REGRA-VISITAS no CI:             [✅ 3 regras | ❌ AUSENTE]
flutter analyze 0 erros novos:   [✅ SIM | ❌ <lista>]
Testes sem regressão:            [✅ SIM | ❌ <falhas>]

DÍVIDAS AINDA ABERTAS:
  DT-023-5 (map/ui/ importam visitas/ direto): [PENDENTE — próximo ciclo]
  DT-023-7 (VisitSession não @immutable):      [PENDENTE — ADR futuro]
  DT-023-8 (Geofence duplicado):               [PENDENTE — ADR futuro]

RESULTADO GERAL:   [✅ APROVADO PARA COMMIT | ❌ BLOQUEADO — ver motivo]

MOTIVO DO BLOQUEIO (se aplicável):
  <lista de itens que falharam>
  <prompt que deve ser re-executado>

MENSAGEM DE COMMIT (se aprovado):
  feat(visitas): blindagem parcial do bounded context — ADR-023

  - Expande IVisitSessionLookup: DTO com 7 campos + findById()
  - Atualiza VisitSessionLookupAdapter com mapeamento completo
  - Remove imports diretos de consultoria/ em visit_controller.dart
  - Remove imports diretos de consultoria/ em geofence_controller.dart
  - Adiciona REGRA-VISITAS-1/2/3 ao arch_check.sh (fecha ponto cego)
  - Cria ADR-023-MODULO-VISITAS.md com dívidas rastreadas
  - Atualiza bounded_contexts.md e enforcement-rules.md
  - arch_check.sh: Exit 0
  - flutter analyze: 0 erros novos
  - Testes: sem regressão (67/67 consultoria, 268/268 drawing)

  Dívidas abertas: DT-023-5, DT-023-7, DT-023-8 (ver ADR-023)
══════════════════════════════════════════════════════════
```

---

## ENCERRAMENTO

Se APROVADO → commitar com a mensagem sugerida acima.
Se BLOQUEADO → corrigir apenas os itens listados e re-executar este PROMPT 06.

Próximo módulo na fila após este commit:
`consultoria/agenda/` vs `modules/agenda/` — duplicidade de lógica.
