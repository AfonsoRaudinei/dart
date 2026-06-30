# ADR-024 PROMPT 07 — AUDITORIA FINAL: Conformidade do ciclo ADR-024
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Auditoria Final (READ-ONLY)
**Tipo:** GATE DE QUALIDADE — zero edição — decide se pode commitar
**Pré-requisito:** PROMMPTs 01–06 do ADR-024 executados
**Risco:** Nenhum — apenas leitura e decisão

---

## OBJETIVO

Confirmar que o ciclo ADR-024 foi executado completamente, que DT-023-3
e DT-023-4 estão de fato resolvidas, e que nenhuma regressão foi
introduzida em nenhum módulo.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar nenhum arquivo
❌ Não corrigir nada — apenas reportar
❌ Não commitar

---

## PASSO 0 — INVENTÁRIO DE ARTEFATOS DO CICLO ADR-024

```bash
# Contratos criados
find lib/core/contracts/ -name "*.dart" | sort

# Adapters criados
find lib/modules/consultoria/fields/infra/ -name "*.dart" | sort
find lib/modules/agenda/ -name "*bridge*" | sort

# Testes criados
find test/modules/visitas/ -name "*.dart" | sort

# ADR criado
find docs/02_ARQUITETURA_ATIVA/ -name "ADR-024*"
```

Esperado — confirmar presença de cada item:
- [ ] `i_occurrence_lookup.dart` em `core/contracts/`
- [ ] `i_report_writer.dart` em `core/contracts/`
- [ ] `i_agenda_session_bridge.dart` em `core/contracts/`
- [ ] `i_field_lookup_geofence_provider.dart` em `core/contracts/`
- [ ] `FieldSummary.geometry` em `i_field_lookup.dart`
- [ ] `IFieldLookup.listAll()` em `i_field_lookup.dart`
- [ ] `FieldLookupGeofenceAdapter` em `consultoria/fields/infra/`
- [ ] `AgendaSessionBridgeAdapter` em `agenda/`
- [ ] `visit_controller_test.dart` em `test/modules/visitas/`
- [ ] `ADR-024-*.md` em `docs/02_ARQUITETURA_ATIVA/`

---

## PASSO 1 — VERIFICAR DT-023-3 RESOLVIDA

```bash
echo "=== visit_controller — imports de consultoria/ ==="
grep -n "import.*modules/consultoria" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart

echo "=== visit_controller — imports diretos de agenda/presentation ==="
grep -n "import.*modules/agenda.*presentation" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart
```

Resultado esperado: **ambos vazios**.
Se qualquer linha retornar → **DT-023-3 NÃO RESOLVIDA — BLOQUEADO**.

---

## PASSO 2 — VERIFICAR DT-023-4 RESOLVIDA

```bash
echo "=== geofence_controller — imports de consultoria/ ==="
grep -n "import.*modules/consultoria" \
  lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

Resultado esperado: **vazio**.
Se qualquer linha retornar → **DT-023-4 NÃO RESOLVIDA — BLOQUEADO**.

---

## PASSO 3 — VERIFICAR CONTRATOS NEUTROS SEM IMPORTS PROIBIDOS

```bash
for f in \
  lib/core/contracts/i_occurrence_lookup.dart \
  lib/core/contracts/i_report_writer.dart \
  lib/core/contracts/i_agenda_session_bridge.dart \
  lib/core/contracts/i_field_lookup_geofence_provider.dart; do
  echo "=== $f ==="
  grep "import.*modules/" "$f" 2>/dev/null && echo "⚠️ IMPORT PROIBIDO" || echo "✅ OK"
done
```

Todos devem retornar `✅ OK`.

---

## PASSO 4 — VERIFICAR ADAPTER DE GEOFENCE SEM IMPORTS PROIBIDOS

```bash
echo "=== FieldLookupGeofenceAdapter — imports de visitas/ ou drawing/ ==="
grep "import.*modules/visitas\|import.*modules/drawing" \
  lib/modules/consultoria/fields/infra/field_lookup_geofence_adapter.dart
```

Resultado esperado: **vazio**.

---

## PASSO 5 — VERIFICAR EXCEÇÕES REMOVIDAS DO ARCH_CHECK

```bash
grep -n "visit_controller\|geofence_controller" tool/arch_check.sh
```

Resultado esperado: **vazio** — as exceções DT-023-3/4 foram removidas
junto com a resolução das dívidas.

Se ainda aparecerem → as exceções são ruído que deve ser removido,
mas não é bloqueante para o commit (apenas boa higiene).

---

## PASSO 6 — ARCH_CHECK COMPLETO SEM EXCEÇÕES

```bash
bash tool/arch_check.sh 2>&1
echo "EXIT CODE: $?"
```

Resultado esperado:
- Exit 0
- `REGRA-VISITAS-1/2/3` não disparam (controllers limpos)
- Sem novas violações em nenhum módulo

---

## PASSO 7 — FLUTTER ANALYZE COMPLETO

```bash
flutter analyze 2>&1 | tail -10
```

Resultado esperado:
- 0 erros novos
- 1 warning pré-existente em `publicacao_editor_screen.dart` (autorizado)
- ~45 infos pré-existentes (não bloqueante)

---

## PASSO 8 — SUITE DE TESTES COMPLETA

```bash
flutter test test/modules/visitas/ 2>&1 | tail -5
flutter test test/modules/consultoria/ 2>&1 | tail -5
flutter test test/drawing/ 2>&1 | tail -5
flutter test test/modules/ 2>&1 | tail -10
```

Esperado:
- `visitas/`: novos testes passando (N/N)
- `consultoria/`: 67/67 ✅
- `drawing/`: 268/268 (ou baseline atual) ✅
- `ndvi/`: 12/12 ✅

---

## PASSO 9 — COMPARATIVO FINAL COM BASELINE ADR-023

| Dívida | Status inicial | Status atual |
|---|---|---|
| DT-023-1: DTO com 2 campos | ✅ Resolvido — PROMPT 03 ciclo visitas | ✅ |
| DT-023-2: sem findById() | ✅ Resolvido — PROMPT 03 ciclo visitas | ✅ |
| DT-023-3: visit_controller imports consultoria | ❌ Pendente | ? |
| DT-023-4: geofence_controller imports consultoria | ❌ Pendente | ? |
| DT-023-5: map/ui importam visitas direto | ❌ Pendente | ❌ Pendente próx. ciclo |
| DT-023-6: ponto cego CI | ✅ Resolvido — PROMPT 05 ciclo visitas | ✅ |
| DT-023-7: VisitSession não @immutable | ❌ Pendente | ❌ ADR futuro |
| DT-023-8: Geofence duplicado | ❌ Pendente | ❌ ADR futuro |

Preencher coluna "Status atual" para DT-023-3 e DT-023-4 com ✅ ou ❌.

---

## RELATÓRIO FINAL

```
══════════════════════════════════════════════════════════
AUDITORIA FINAL — ADR-024 — GATE DE QUALIDADE
Data: <hoje>
══════════════════════════════════════════════════════════

ARTEFATOS ADR-024 presentes:     [✅ todos | ❌ faltando: <lista>]
DT-023-3 resolvida:              [✅ SIM | ❌ NÃO]
DT-023-4 resolvida:              [✅ SIM | ❌ NÃO]
Contratos neutros sem imports:   [✅ SIM | ❌ <arquivo com violação>]
Adapter geofence isolado:        [✅ SIM | ❌ NÃO]
Exceções arch_check removidas:   [✅ SIM | ⚠️ ainda presentes — não bloqueante]
arch_check.sh Exit 0:            [✅ SIM | ❌ EXIT 1]
flutter analyze 0 erros novos:   [✅ SIM | ❌ <erros>]
Testes visitas/ passando:        [✅ N/N | ❌ <falhas>]
Testes consultoria/ 67/67:       [✅ SIM | ❌ <falhas>]
Testes drawing/ baseline:        [✅ SIM | ❌ <falhas>]
Testes ndvi/ 12/12:              [✅ SIM | ❌ <falhas>]

DÍVIDAS RESOLVIDAS NESTE CICLO:
  ✅ DT-023-3 — visit_controller limpo
  ✅ DT-023-4 — geofence_controller limpo

DÍVIDAS AINDA ABERTAS (registradas, não bloqueantes):
  ⏳ DT-023-5 — map/ui/ importam visitas/ direto
  ⏳ DT-023-7 — VisitSession não @immutable
  ⏳ DT-023-8 — Geofence duplicado operacao/ vs visitas/

RESULTADO GERAL: [✅ APROVADO PARA COMMIT | ❌ BLOQUEADO — <motivo>]

MENSAGEM DE COMMIT SUGERIDA (se aprovado):
  feat(visitas,adr024): resolve DT-023-3 e DT-023-4 — blindagem completa

  Contratos criados (core/contracts/):
  - IOccurrenceLookup + provider
  - IReportWriter + provider
  - IAgendaSessionBridge + provider
  - IFieldLookupGeofence + provider
  - IFieldLookup expandido: geometry + listAll()

  Adapters criados:
  - AgendaSessionBridgeAdapter (agenda/)
  - FieldLookupGeofenceAdapter (consultoria/fields/infra/)

  Migrações:
  - visit_controller.dart: 3 imports de consultoria/ removidos
  - geofence_controller.dart: 3 imports de consultoria/ removidos
  - TalhaoMapAdapter inlinado como funções puras

  Testes:
  - visit_controller_test.dart: N cenários com 3 fakes
  - FakeFieldLookup.listAll() adicionado (ndvi 12/12)

  CI:
  - arch_check.sh: exceções DT-023-3/4 removidas
  - arch_check.sh: Exit 0 sem exceções

  ADR-023: DT-023-3 e DT-023-4 marcadas como resolvidas
  ADR-024: ciclo fechado

  Dívidas abertas: DT-023-5/7/8 (ver ADR-023 §9)
══════════════════════════════════════════════════════════
```

---

## ENCERRAMENTO

Se APROVADO → commitar com a mensagem acima.
Se BLOQUEADO → corrigir apenas os itens listados e re-executar este PROMPT 07.

Após commit, o módulo `visitas/` estará completamente blindado:
- Contrato formal (ADR-023)
- Interface expandida (IVisitSessionLookup)
- Zero imports de consultoria/ em qualquer arquivo de visitas/
- CI cobrindo toda a camada sem exceções autorizadas

Próximo módulo na fila: `map/` — ADR formal do agregador
(maior superfície de acoplamento do projeto).
