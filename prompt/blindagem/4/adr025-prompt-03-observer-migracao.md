# ADR-025 PROMPT 03 — MIGRAÇÃO: `visit_completion_observer.dart`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Cirurgia de Acoplamento
**Arquivo alvo:** `lib/modules/map/presentation/providers/visit_completion_observer.dart`
**Tipo:** ALTERAÇÃO ESTRUTURAL — substituição de imports concretos por contratos
**Pré-requisito:** PROMPT 02 concluído — ADR-025 criado, REGRA-MAP-1 ativa
**Risco:** Médio — observer crítico do ciclo de vida de visita

---

## OBJETIVO

Substituir os 7 imports concretos de `visit_completion_observer.dart`
pelos contratos neutros já disponíveis em `core/contracts/` (ADR-024).
Resolver DT-025-2 e DT-025-8 (proxy ADR-010) no mesmo commit.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não alterar a lógica de disparo do observer
❌ Não alterar `main.dart` além do necessário para o override
❌ Não criar contratos novos — todos já existem do ADR-024
❌ Não ultrapassar 900 linhas no arquivo resultante
❌ Se encontrar import sem contrato correspondente → PARAR e reportar

---

## PASSO 0 — LEITURA COMPLETA

```bash
cat lib/modules/map/presentation/providers/visit_completion_observer.dart

# Confirmar contratos disponíveis do ADR-024
find lib/core/contracts/ -name "*.dart" | sort | xargs grep -l "interface\|abstract"

# Ler cada contrato relevante
cat lib/core/contracts/i_occurrence_lookup.dart   2>/dev/null || echo "AUSENTE"
cat lib/core/contracts/i_agenda_session_bridge.dart 2>/dev/null || echo "AUSENTE"
cat lib/core/contracts/i_report_writer.dart        2>/dev/null || echo "AUSENTE"
```

Antes de editar, montar a tabela de substituição:

```
Import concreto atual                              → Contrato neutro
────────────────────────────────────────────────────────────────────
agenda/domain/entities/event.dart                  → via IAgendaSessionBridge (sem expor Event)
agenda/domain/entities/visit_session.dart          → VisitSessionSummary (IVisitSessionLookup)
agenda/presentation/providers/agenda_provider.dart → iAgendaSessionBridgeProvider
consultoria/occurrences/data/occurrence_repository → IOccurrenceLookup
consultoria/occurrences/presentation/controllers/… → IOccurrenceLookup (mesma interface)
consultoria/relatorios/models/visit_session_snapshot → DTO interno do observer (não expor)
consultoria/relatorios/use_cases/generate_relatorio → IReportWriter
```

Se qualquer import não tiver substituto identificado → PARAR antes de continuar.

---

## PASSO 1 — IDENTIFICAR USOS CONCRETOS NO OBSERVER

```bash
grep -n "Event\b\|VisitSession\b\|agendaProvider\|agendaRepositoryProvider\
\|OccurrenceRepository\|OccurrenceController\|VisitSessionSnapshot\
\|GenerateRelatorioUseCase\|generate_relatorio" \
  lib/modules/map/presentation/providers/visit_completion_observer.dart
```

Para cada ocorrência, anotar:
- Linha exata
- Método chamado
- Dados usados do objeto retornado

---

## PASSO 2 — SUBSTITUIR IMPORTS

Remover os 7 imports concretos e adicionar:

```dart
import 'package:soloforte_app/core/contracts/i_occurrence_lookup.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/core/contracts/i_report_writer.dart';
import 'package:soloforte_app/core/contracts/i_report_writer_provider.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
```

Verificar quais providers existem:
```bash
find lib/core/contracts/ -name "i_*_provider.dart" | sort
```

Usar apenas os providers que existem. Não criar providers novos.

---

## PASSO 3 — ATUALIZAR INJEÇÃO DE DEPENDÊNCIA

O observer usa `ref.watch` / `ref.read` para acessar repositórios.
Substituir cada acesso concreto pelo provider neutro:

```dart
// ANTES
final agendaRepo = ref.watch(agendaRepositoryProvider);
final occurrenceRepo = OccurrenceRepository();

// DEPOIS
final agendaBridge = ref.watch(iAgendaSessionBridgeProvider);
final occurrenceLookup = ref.watch(iOccurrenceLookupProvider);
final reportWriter = ref.watch(iReportWriterProvider);
```

---

## PASSO 4 — RESOLVER DT-025-8 (PROXY ADR-010)

Localizar o proxy de `farmName`:

```bash
grep -n "farmName\|fazendaId\|event\.titulo\|TODO.*ADR-010" \
  lib/modules/map/presentation/providers/visit_completion_observer.dart
```

O proxy atual é algo como:
```dart
farmName: event.fazendaId ?? 'Fazenda não identificada',
// TODO(ADR-010): proxy temporário
```

**Opção A** (preferida se `IAgendaSessionBridge` expõe `farmName`):
```dart
final farmName = await agendaBridge.getFarmNameForSession(sessionId);
```

**Opção B** (se o contrato não expõe `farmName`):
Manter o proxy mas documentar como DT-025-8 PENDENTE no código:
```dart
// DT-025-8: farmName ainda via proxy event.fazendaId
// Condição de encerramento: IAgendaSessionBridge expor getFarmName()
farmName: session.areaId ?? 'Fazenda não identificada',
```

Reportar qual opção foi aplicada.

---

## PASSO 5 — ADAPTAR TIPOS

`Event` e `VisitSession` concretos devem ser substituídos por DTOs neutros:
- `Event` → usar apenas os campos acessados, via `IAgendaSessionBridge`
- `VisitSession` → `VisitSessionSummary` (já disponível)
- `VisitSessionSnapshot` → construir localmente no observer a partir dos DTOs

```bash
# Verificar campos de VisitSessionSummary
grep -A 15 "class VisitSessionSummary" lib/core/contracts/i_visit_session_lookup.dart
```

O observer não deve importar `VisitSessionSnapshot` de `consultoria/`.
Se precisar construir o snapshot, usa apenas campos dos DTOs neutros.

---

## PASSO 6 — VERIFICAR CONTAGEM DE LINHAS

```bash
wc -l lib/modules/map/presentation/providers/visit_completion_observer.dart
```

Deve ficar abaixo de 900. Se ultrapassar → extrair método privado
para arquivo auxiliar antes de commitar.

---

## PASSO 7 — VERIFICAR IMPORTS PROIBIDOS ELIMINADOS

```bash
grep -n "import.*modules/consultoria\|import.*modules/agenda" \
  lib/modules/map/presentation/providers/visit_completion_observer.dart
```

Resultado esperado: **vazio**.

---

## PASSO 8 — VERIFICAR ARCH_CHECK

```bash
bash tool/arch_check.sh
echo "EXIT CODE: $?"
```

REGRA-MAP-1 não deve disparar (o observer está dentro de `map/`).
Exit 0 esperado.

---

## PASSO 9 — FLUTTER ANALYZE

```bash
flutter analyze lib/modules/map/ 2>&1 | grep -E "^.*error"
flutter analyze lib/modules/consultoria/ 2>&1 | grep -E "^.*error"
flutter analyze lib/modules/agenda/ 2>&1 | grep -E "^.*error"
```

Zero erros novos.

---

## PASSO 10 — TESTES

```bash
flutter test test/modules/consultoria/ 2>&1 | tail -5
flutter test test/drawing/ 2>&1 | tail -5
```

Baseline: 67/67 consultoria, 268/268 drawing.

---

## PASSO 11 — ATUALIZAR ADR-025

```
DT-025-2: visit_completion_observer com 7 imports concretos → ✅ RESOLVIDO
DT-025-8: proxy ADR-010 → [✅ RESOLVIDO | ⏳ PENDENTE com novo ID]
```

---

## VALIDAÇÃO FINAL

- [ ] `visit_completion_observer.dart` sem imports de `consultoria/`?
- [ ] `visit_completion_observer.dart` sem imports concretos de `agenda/`?
- [ ] Lógica do observer inalterada?
- [ ] Abaixo de 900 linhas?
- [ ] Proxy ADR-010 tratado (resolvido ou re-documentado)?
- [ ] `arch_check.sh` Exit 0?
- [ ] `flutter analyze` sem erros novos?
- [ ] Testes sem regressão?
- [ ] ADR-025 atualizado com DT-025-2 resolvida?

---

## MENSAGEM DE COMMIT

```
feat(map,adr025): migra visit_completion_observer para contratos ADR-024

- Remove 7 imports concretos de consultoria/ e agenda/
- Substitui por: IOccurrenceLookup, IAgendaSessionBridge, IReportWriter
- VisitSession → VisitSessionSummary (contrato neutro)
- DT-025-2: ✅ resolvida
- DT-025-8 (proxy farmName): [resolvido | re-documentado como DT-025-8b]
- arch_check.sh: Exit 0
- flutter analyze: 0 erros novos
- Testes: sem regressão
```

---

## ENCERRAMENTO

`visit_completion_observer.dart` sem dependências concretas de
`consultoria/` ou `agenda/`.
Próximo: PROMPT 04 — auditoria final ADR-025 + governance de
`private_map_screen.dart`.
