# ADR-025 PROMPT 04 — AUDITORIA FINAL + GOVERNANCE `private_map_screen.dart`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Auditoria Final (READ-ONLY)
**Tipo:** GATE DE QUALIDADE + GOVERNANCE — decide commit e registra regra
**Pré-requisito:** PROMMPTs 01–03 do ADR-025 executados
**Risco:** Nenhum — leitura, decisão e 1 adição documental

---

## OBJETIVO

Confirmar que o ciclo ADR-025 Fases 1 e 2 estão corretas,
emitir o veredito de commit, e estabelecer a regra de governance
para `private_map_screen.dart` antes que ultrapasse 900 linhas.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar arquivos Dart
❌ Não corrigir nada — apenas reportar e documentar governance
❌ Não commitar

---

## PASSO 0 — INVENTÁRIO DE ARTEFATOS

```bash
# sf_icons no lugar certo
find lib/core/design/ -name "sf_icons.dart"
find lib/modules/map/design/ -name "sf_icons.dart" 2>/dev/null \
  && echo "⚠️ ORIGINAL AINDA EXISTE" || echo "✅ ORIGINAL DELETADO"

# ADR-025 existe
find docs/02_ARQUITETURA_ATIVA/ -name "ADR-025*"

# REGRA-MAP-1 no CI
grep -n "REGRA-MAP-1" tool/arch_check.sh

# Observer migrado
grep -n "import.*modules/consultoria\|import.*modules/agenda" \
  lib/modules/map/presentation/providers/visit_completion_observer.dart \
  | grep -v "^\s*//"
```

---

## PASSO 1 — VERIFICAR DT-025-1 RESOLVIDA

```bash
grep -rn "modules/map/design/sf_icons" lib/ --include="*.dart"
```

Resultado esperado: **vazio**.
Se retornar qualquer linha → **DT-025-1 NÃO RESOLVIDA — BLOQUEADO**.

---

## PASSO 2 — VERIFICAR DT-025-2 RESOLVIDA

```bash
grep -n "import.*modules/consultoria\|import.*modules/agenda" \
  lib/modules/map/presentation/providers/visit_completion_observer.dart
```

Resultado esperado: **vazio**.
Se retornar qualquer linha → **DT-025-2 NÃO RESOLVIDA — BLOQUEADO**.

---

## PASSO 3 — VERIFICAR REGRA-MAP-1 FUNCIONA

```bash
# Simular violação temporária
echo "import 'package:soloforte_app/modules/map/design/test.dart';" \
  > lib/modules/consultoria/test_map_violation_temp.dart

bash tool/arch_check.sh 2>&1 | grep "REGRA-MAP-1"

rm lib/modules/consultoria/test_map_violation_temp.dart
```

Se `REGRA-MAP-1 VIOLADA` aparecer → regra funciona ✅
Se não aparecer → regra tem problema — reportar antes de commitar.

---

## PASSO 4 — ARCH_CHECK COMPLETO

```bash
bash tool/arch_check.sh 2>&1
echo "EXIT CODE: $?"
```

Resultado esperado:
- Exit 0
- REGRA-MAP-1 ativa sem disparar
- REGRA-VISITAS-1/2/3 ativas sem disparar
- Violações pré-existentes autorizadas listadas (não novas)

---

## PASSO 5 — FLUTTER ANALYZE COMPLETO

```bash
flutter analyze 2>&1 | tail -10
```

Resultado esperado:
- 0 erros novos
- 1 warning pré-existente em `publicacao_editor_screen.dart`

---

## PASSO 6 — TESTES COMPLETOS

```bash
flutter test test/modules/consultoria/ 2>&1 | tail -5
flutter test test/drawing/ 2>&1 | tail -5
flutter test test/modules/ 2>&1 | tail -10
```

Baseline: 67/67 consultoria, 268/268 drawing, 12/12 ndvi.

---

## PASSO 7 — GOVERNANCE DE `private_map_screen.dart`

```bash
wc -l lib/ui/screens/private_map_screen.dart
```

Com 898 linhas — 2 abaixo do limite.

Adicionar comentário de governance no topo do arquivo
(único edit permitido neste PASSO — 3 linhas de comentário):

```dart
// ════════════════════════════════════════════════════════════════
// GOVERNANCE ADR-025 — DT-025-5
// Este arquivo está em 898/900 linhas. PROIBIDO adicionar código
// inline. Toda nova funcionalidade DEVE ser extraída para widget
// separado e apenas referenciada aqui. Ver ADR-025 seção 6.
// ════════════════════════════════════════════════════════════════
```

Inserir após os imports, antes do primeiro `class`.

Verificar contagem após inserção:
```bash
wc -l lib/ui/screens/private_map_screen.dart
```

Deve ser 901–902 linhas agora. Isso aciona o WARN do `arch_check.sh`
(não Exit 1 — é legado monitorado). Confirmar:

```bash
bash tool/arch_check.sh 2>&1 | grep "private_map_screen"
```

Esperado: listado como WARN, não como violação bloqueante.

---

## PASSO 8 — TABELA DE DÍVIDAS FINAL ADR-025

```
DT-025-1: sf_icons.dart movido             → [✅ | ❌]
DT-025-2: observer migrado                 → [✅ | ❌]
DT-025-3: lib/ui/ → visitas/ direto        → [⏳ próximo ciclo]
DT-025-4: fragmentação em 3 locais         → [⏳ ADR futuro]
DT-025-5: private_map_screen 898 linhas    → [⚠️ GOVERNANCE aplicada]
DT-025-6: map_occurrence_sheet 1089 linhas → [⏳ monitorado]
DT-025-7: map_ui_providers em core/state/  → [⏳ ADR futuro]
DT-025-8: proxy farmName ADR-010           → [✅ | ⏳ com novo status]
```

---

## RELATÓRIO FINAL

```
══════════════════════════════════════════════════════════
AUDITORIA FINAL — ADR-025 — GATE DE QUALIDADE
Data: <hoje>
══════════════════════════════════════════════════════════

sf_icons.dart movido (DT-025-1):    [✅ | ❌]
observer migrado (DT-025-2):        [✅ | ❌]
REGRA-MAP-1 funcional:              [✅ | ❌]
arch_check.sh Exit 0:               [✅ | ❌]
flutter analyze 0 erros novos:      [✅ | ❌]
Testes sem regressão:               [✅ | ❌]
Governance private_map inserida:    [✅ | ❌]

DÍVIDAS RESOLVIDAS NESTE CICLO:
  ✅ DT-025-1 — sf_icons fora do namespace errado
  ✅ DT-025-2 — observer sem imports concretos
  ✅ DT-025-8 — proxy ADR-010 [resolvido | re-documentado]

DÍVIDAS REGISTRADAS PARA CICLOS FUTUROS:
  ⏳ DT-025-3 — lib/ui/ → visitas/ direto
  ⏳ DT-025-4 — consolidação lib/ui/components/map/ → lib/modules/map/
  ⚠️ DT-025-5 — private_map_screen governance ativa
  ⏳ DT-025-6 — map_occurrence_sheet monitorado
  ⏳ DT-025-7 — map_ui_providers mislocado

RESULTADO GERAL: [✅ APROVADO | ❌ BLOQUEADO — <motivo>]

MENSAGEM DE COMMIT FINAL (se aprovado):
  feat(map,adr025): Fases 1+2 — bounded context formal + governance

  Fase 1 (documental + CI):
  - Move sf_icons.dart: modules/map/design/ → core/design/
  - Cria ADR-025 com 8 dívidas rastreadas
  - Adiciona REGRA-MAP-1 ao arch_check.sh
  - Atualiza bounded_contexts.md

  Fase 2 (migração observer):
  - visit_completion_observer: 7 imports concretos → contratos ADR-024
  - DT-025-2: ✅ resolvida
  - DT-025-8: [resolvido | re-documentado]

  Governance:
  - private_map_screen.dart: comentário de governance inserido (898→901 ln)
  - Arquivo listado como WARN monitorado no arch_check.sh

  arch_check.sh: Exit 0 | REGRA-MAP-1 ativa
  flutter analyze: 0 erros novos
  Testes: sem regressão

  Dívidas abertas: DT-025-3/4/5/6/7 (ver ADR-025)
  Próximo ciclo: DT-025-3 — lib/ui/ → visitas/ (DT-023-5)
══════════════════════════════════════════════════════════
```

---

## ENCERRAMENTO

Se APROVADO → commitar com a mensagem acima.

Estado do módulo `map/` após este ciclo:
- Bounded context formal declarado (ADR-025)
- REGRA-MAP-1 ativa no CI
- Observer sem dependências concretas
- Governance de crescimento aplicada
- 5 dívidas rastreadas para ciclos futuros

Próximo módulo prioritário: DT-025-3 = DT-023-5 —
`lib/ui/` importa `visitas/` direto.
Esse é o elo que conecta os dois ciclos anteriores.
