# FIX — ADR-018 REGREDIDO: visit_controller → IAgendaRepository
## Sessão 4 — Restaurar contrato de interface no visit_controller

**Agente:** Engenheiro Sênior Flutter/Dart  
**Destino:** `prompt/FIX_ADR018_VISIT_CONTROLLER.md`  
**Execução imediata:** NÃO — PASSO 0 obrigatório + plano antes de editar.  
**Tipo:** Bugfix de regressão — bounded context

---

## CONTEXTO

O ADR-018 foi executado em Mar/2026 com objetivo de eliminar a dependência
direta do `visit_controller.dart` no `AgendaRepository` concreto, migrando
para a interface `IAgendaRepository` via DIP.

A confirmação de auditoria (23/03/2026) revelou que a regressão ocorreu:

```
Confirmação auditoria:
B.2 Usa IAgendaRepository: [ NÃO — usa concreto AgendaRepository
     (import linha 7, campo linha 38) ]
B.3 getEventBySessionId na interface: [ SIM ]
Veredito: [ REGRESSÃO — precisa correção ]
```

O contrato `IAgendaRepository` já existe e já tem `getEventBySessionId`.
A correção é restabelecer o uso da interface no controller.

---

## ESCOPO

**Módulo:** `visitas`  
**Arquivo alvo:** `lib/modules/visitas/presentation/controllers/visit_controller.dart`  

🚫 Proibido alterar `i_agenda_repository.dart`  
🚫 Proibido alterar `agenda_repository.dart` (implementação concreta)  
🚫 Proibido alterar outros módulos  
🚫 Proibido alterar providers fora do escopo  
🚫 Proibido criar novos métodos ou interfaces  

---

## PASSO 0 — LEITURA OBRIGATÓRIA

```bash
# 0.1 — Localizar os arquivos relevantes
find lib/ -name "visit_controller.dart" | grep -v test
find lib/ -name "i_agenda_repository.dart" | grep -v test

# 0.2 — Ler o visit_controller completo
cat lib/modules/visitas/presentation/controllers/visit_controller.dart

# 0.3 — Confirmar import atual (AgendaRepository concreto ou interface?)
grep -n "import.*agenda\|AgendaRepository\|IAgendaRepository" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart

# 0.4 — Ver como IAgendaRepository é declarada
cat lib/modules/agenda/domain/repositories/i_agenda_repository.dart

# 0.5 — Confirmar que getEventBySessionId existe na interface
grep -n "getEventBySessionId" \
  lib/modules/agenda/domain/repositories/i_agenda_repository.dart

# 0.6 — Ver como outros controllers injetam IAgendaRepository (padrão aprovado)
grep -rn "IAgendaRepository" lib/ --include="*.dart" | \
  grep -v test | grep -v ".g.dart" | grep -v "i_agenda_repository.dart"

# 0.7 — Verificar provider que expõe IAgendaRepository
grep -rn "agendaRepositoryProvider\|IAgendaRepository" \
  lib/modules/agenda/ --include="*.dart" | \
  grep -v test | grep -v ".g.dart" | head -10

# 0.8 — Verificar se visit_controller é Riverpod Notifier ou classe simples
grep -n "class VisitController\|extends\|@riverpod\|Notifier\|ChangeNotifier" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart | head -10

# 0.9 — Baseline de testes antes da mudança
find test/ -path "*visitas*" -name "*.dart" | grep -v ".g.dart"
flutter test test/modules/consultoria/ test/core/ \
  --reporter compact 2>&1 | tail -5
```

---

## REGRAS DE IMPLEMENTAÇÃO

### Regra 1 — Substituir import concreto por interface

**De:**
```dart
import 'package:soloforte_app/modules/agenda/data/repositories/agenda_repository.dart';
```

**Para:**
```dart
import 'package:soloforte_app/modules/agenda/domain/repositories/i_agenda_repository.dart';
```

O caminho exato é confirmado no PASSO 0.4.

### Regra 2 — Substituir tipo do campo

**De:**
```dart
final AgendaRepository _agendaRepository;
// ou
AgendaRepository _agendaRepository;
```

**Para:**
```dart
final IAgendaRepository _agendaRepository;
```

### Regra 3 — Injeção via provider

Se o controller recebe o repositório via construtor, verificar se
o provider que instancia o controller passa `IAgendaRepository`.

O padrão aprovado para injeção (PASSO 0.6) deve ser seguido.
Não criar novo provider — usar o `agendaRepositoryProvider` existente
que já expõe `IAgendaRepository`.

### Regra 4 — Não alterar chamadas de método

Os métodos chamados (`getEventBySessionId`, etc.) já existem em
`IAgendaRepository` (confirmado pela auditoria). Nenhuma chamada de
método precisa ser alterada — apenas o tipo da dependência.

### Regra 5 — Hard stop

Se `getEventBySessionId` **não estiver** na interface (contradizendo
a auditoria) → PARAR e reportar. Não adicionar método à interface
sem autorização explícita.

---

## SEQUÊNCIA DE EXECUÇÃO

```
1. PASSO 0 completo → reportar todos os outputs
2. Apresentar plano:
   - Linha do import atual → linha do import novo
   - Linha do tipo atual → linha do tipo novo
   - Confirmar que nenhuma chamada de método muda
3. Aguardar aprovação
4. Aplicar correção
5. Gate checks
6. Commit
```

---

## GATE CHECKS

```bash
# Gate 1 — Sem erros no arquivo corrigido
flutter analyze \
  lib/modules/visitas/presentation/controllers/visit_controller.dart \
  2>&1 | tail -5

# Gate 2 — Testes não regredidos
flutter test test/modules/consultoria/ test/core/ \
  --reporter compact 2>&1 | tail -5

# Gate 3 — arch_check mantido
./tool/arch_check.sh 2>&1 | tail -8

# Gate 4 — Confirmar que import concreto foi removido
grep -n "import.*AgendaRepository[^I]" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart && \
  echo "FALHA: import concreto ainda presente" || \
  echo "OK: import concreto removido"

# Gate 5 — Confirmar que interface está sendo usada
grep -n "IAgendaRepository" \
  lib/modules/visitas/presentation/controllers/visit_controller.dart
```

**Critério de aprovação:**
- Gate 1: 0 erros
- Gate 2: todos os testes verdes
- Gate 3: EXIT 0
- Gate 4: mensagem "OK: import concreto removido"
- Gate 5: pelo menos 1 match confirmando uso da interface

---

## COMMIT

```bash
git add lib/modules/visitas/presentation/controllers/visit_controller.dart
git commit -m "fix(visitas): visit_controller migrado para IAgendaRepository — restaura ADR-018"
```

Nunca usar `git add .` ou `git add -A`.

---

## VALIDAÇÃO FINAL

| Verificação | Esperado |
|---|---|
| Import de `AgendaRepository` concreto removido? | SIM |
| Import de `IAgendaRepository` adicionado? | SIM |
| Tipo do campo atualizado para `IAgendaRepository`? | SIM |
| Chamadas de método alteradas? | NÃO |
| Outros arquivos alterados? | NÃO |
| Testes verdes? | SIM |
| arch_check EXIT 0? | SIM |

---

## ENCERRAMENTO PADRÃO

```
Resultado final:
visit_controller.dart migrado de AgendaRepository concreto para IAgendaRepository.
ADR-018 restaurado — bounded context visitas/agenda respeitado via DIP.
Nenhum outro arquivo foi alterado.
```

---

*Prompt gerado para: SoloForte App — Sessão 4 pós-auditoria*  
*Origem: Regressão confirmada em auditoria 23/03/2026*  
*Arquivo alvo: lib/modules/visitas/presentation/controllers/visit_controller.dart*
