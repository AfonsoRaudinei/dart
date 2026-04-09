# PROMPT 04 — DESACOPLAMENTO: `visit_controller.dart` e `geofence_controller.dart`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Cirurgia de Acoplamento
**Arquivos alvo:**
  - `lib/modules/visitas/presentation/controllers/visit_controller.dart`
  - `lib/modules/visitas/presentation/controllers/geofence_controller.dart`
**Tipo:** ALTERAÇÃO ESTRUTURAL — remoção de imports proibidos via DIP
**Pré-requisito:** PROMPT 03 executado — DTO e interface expandidos
**Risco:** ALTO — arquivos críticos com lógica de campo

---

## OBJETIVO

Remover os 6 imports diretos de `consultoria/` e `agenda/` de dentro de
`visitas/`, substituindo-os por contratos existentes em `core/contracts/`
ou por injeção de dependência via Riverpod.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não alterar lógica de negócio — apenas trocar a origem dos tipos
❌ Não alterar `VisitSession` nem o repositório
❌ Não criar novos bounded contexts
❌ Não ultrapassar 900 linhas nos arquivos alterados
❌ Não usar `dynamic` para contornar tipagem — toda substituição deve ser tipada
❌ Se a substituição exigir criar contrato novo em `core/contracts/` → PARAR e reportar antes de criar

---

## PASSO 0 — VERIFICAÇÃO E LEITURA COMPLETA

```bash
find lib/modules/visitas/presentation/controllers/ -name "*.dart" | sort
cat lib/modules/visitas/presentation/controllers/visit_controller.dart
cat lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

Antes de qualquer edição, ler os arquivos completos e identificar:
1. Quais tipos de `consultoria/` são usados e onde
2. Quais tipos de `agenda/` são usados e onde
3. Se há contrato equivalente já em `core/contracts/`

```bash
find lib/core/contracts/ -type f -name "*.dart" | sort
```

---

## PASSO 1 — ANÁLISE DE `visit_controller.dart`

Imports proibidos confirmados pelo PROMPT 01:
```
consultoria/occurrences/data/occurrence_repository.dart  ← repositório concreto
consultoria/reports/data/sqlite_report_repository.dart   ← repositório concreto
consultoria/reports/domain/report_model.dart             ← entidade de domínio
agenda/domain/repositories/i_agenda_repository.dart      ← interface (avaliar)
agenda/domain/enums/event_status.dart                    ← enum puro
agenda/presentation/providers/agenda_provider.dart       ← provider direto
```

Para cada import, determinar a estratégia:

**`occurrence_repository.dart` (concreto de consultoria)**
→ Verificar se existe `IOccurrenceRepository` em `core/contracts/`
```bash
find lib/core/contracts/ -name "*occurrence*" | sort
find lib/ -name "i_occurrence_repository.dart" | sort
```
→ Se existir: substituir pelo contrato + injetar via provider
→ Se não existir: **PARAR — declarar necessidade ao usuário antes de continuar**

**`sqlite_report_repository.dart` + `report_model.dart` (concreto de consultoria)**
→ Verificar se existe `IReportRepository` ou similar
```bash
find lib/core/contracts/ -name "*report*" | sort
find lib/modules/consultoria/reports/ -name "i_report*.dart" | sort
```
→ Se existir: substituir
→ Se não existir: **PARAR — declarar necessidade ao usuário**

**`i_agenda_repository.dart` (interface de agenda)**
→ Interface já é DIP — mas está sendo importada fora da zona neutra
→ Verificar: está em `core/contracts/` ou em `agenda/domain/`?
```bash
find lib/core/contracts/ -name "*agenda*" | sort
```
→ Se em `agenda/domain/`: o acoplamento viola a fronteira — avaliar se deve migrar para `core/contracts/`
→ Reportar decisão antes de migrar

**`event_status.dart` (enum de agenda)**
→ Enum puro importado em `visitas/`
→ Verificar o que `visit_controller` faz com ele:
```bash
grep -n "EventStatus\|event_status" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart
```
→ Se for apenas leitura de status: criar enum espelho em `visitas/domain/` ou usar String
→ Reportar antes de criar

**`agenda_provider.dart` (provider de agenda importado em visitas)**
→ Isso é acoplamento direto de presentation → presentation entre módulos
→ Identificar por que `visit_controller` precisa do provider de agenda:
```bash
grep -n "agendaProvider\|AgendaProvider\|agendaNotifier" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart
```
→ Substituir por injeção de dependência — receber via construtor ou `ref.watch`
→ Se precisar do `IAgendaRepository`: injetar via `core/contracts/` (verificar se existe)

---

## PASSO 2 — ANÁLISE DE `geofence_controller.dart`

Imports proibidos confirmados pelo PROMPT 01:
```
consultoria/clients/presentation/providers/field_providers.dart  ← provider de consultoria
consultoria/services/talhao_map_adapter.dart                    ← serviço de consultoria
consultoria/clients/domain/agronomic_models.dart                ← entidade de consultoria
```

```bash
grep -n "FieldProvider\|TalhaoMapAdapter\|AgronomicModel\|fieldProvider\|talhaoMap" \
  lib/modules/visitas/presentation/controllers/geofence_controller.dart
```

Para cada import:
→ Verificar se existe `IFieldLookup` em `core/contracts/` (foi criado no ADR-022)
```bash
find lib/core/contracts/ -name "i_field_lookup.dart"
cat lib/core/contracts/i_field_lookup.dart
```
→ Se `IFieldLookup` cobre o que `field_providers` e `agronomic_models` proveem:
  substituir o import direto pelo contrato
→ `talhao_map_adapter.dart`: verificar se é um serviço de transformação ou repositório
```bash
cat lib/modules/consultoria/services/talhao_map_adapter.dart 2>/dev/null | head -50
```
→ Se for adaptador de coordenadas/geometria: avaliar mover para `core/` ou criar contrato

---

## PASSO 3 — EXECUTAR SUBSTITUIÇÕES (somente após PASSOS 1 e 2 completos)

⚠️ **REGRA DE PARADA:** Se qualquer substituição exigir criar um contrato novo
em `core/contracts/` que não existe, PARAR e reportar ao usuário.
Não criar contratos novos sem validação explícita.

Para cada substituição aprovada:
1. Substituir o import proibido pelo import do contrato em `core/contracts/`
2. Atualizar a assinatura do construtor ou dos métodos para receber o tipo do contrato
3. Garantir que a lógica de negócio não foi alterada — apenas a origem do tipo

---

## PASSO 4 — VERIFICAR CADA ARQUIVO APÓS EDIÇÃO

```bash
flutter analyze lib/modules/visitas/presentation/controllers/visit_controller.dart 2>&1
flutter analyze lib/modules/visitas/presentation/controllers/geofence_controller.dart 2>&1
```

Zero erros novos. Se houver erro → PARAR antes de continuar.

---

## PASSO 5 — VERIFICAR MÓDULOS CONSUMIDORES

```bash
flutter analyze lib/modules/map/ 2>&1 | grep -E "error|Error"
flutter analyze lib/modules/consultoria/ 2>&1 | grep -E "error|Error"
flutter analyze lib/modules/agenda/ 2>&1 | grep -E "error|Error"
```

Todos devem continuar com 0 erros novos.

---

## PASSO 6 — VERIFICAR IMPORTS PROIBIDOS ELIMINADOS

```bash
grep -n "import.*modules/consultoria" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart

grep -n "import.*modules/consultoria" \
  lib/modules/visitas/presentation/controllers/geofence_controller.dart

grep -n "import.*presentation/providers/agenda_provider" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart
```

Todos os resultados devem ser **vazios** após as substituições.

---

## PASSO 7 — ARCH_CHECK

```bash
bash tool/arch_check.sh
echo "EXIT CODE: $?"
```

Resultado esperado: **Exit 0**.

---

## PASSO 8 — ATUALIZAR ADR-023

Marcar dívidas resolvidas:
```
DT-023-3: visit_controller.dart sem imports de consultoria → ✅ RESOLVIDO — PROMPT 04
DT-023-4: geofence_controller.dart sem imports de consultoria → ✅ RESOLVIDO — PROMPT 04
```

Se alguma dívida ficou pendente (ex: contrato novo necessário), registrar
nova entrada DT-023-N com status PENDENTE e motivo.

---

## VALIDAÇÃO FINAL

- [ ] `visit_controller.dart` sem imports de `consultoria/`?
- [ ] `visit_controller.dart` sem imports diretos de `agenda/presentation/`?
- [ ] `geofence_controller.dart` sem imports de `consultoria/`?
- [ ] Lógica de negócio inalterada?
- [ ] `flutter analyze` em `visitas/`, `map/`, `consultoria/`, `agenda/` sem erros novos?
- [ ] `arch_check.sh` Exit 0?
- [ ] ADR-023 atualizado?

---

## ENCERRAMENTO

Os controllers de `visitas/` estão desacoplados de `consultoria/` e `agenda/`.
Todo acesso a dados externos passa por contratos em `core/contracts/`.
O PROMPT 05 fecha o ciclo adicionando cobertura de CI para esta camada.
