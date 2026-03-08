# PROMPT — Grupo C: Refatoração AppBars do Módulo agenda/

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em GoRouter e Navegação Declarativa
**Tipo:** Correção Estrutural — pop() Proibido + AppBar Leading Automático
**PRD Referência:** PRD_SMART_BUTTON_UNIFICACAO.md — Erro 5 — Prioridade 2 Alta
**Branch:** release/v1.1

---

## 1. ESCOPO

**Módulo:** `agenda/`

**Arquivos tocados (apenas estes):**
- `lib/modules/agenda/presentation/pages/agenda_month_page.dart`
- `lib/modules/agenda/presentation/pages/agenda_day_page.dart`
- `lib/modules/agenda/presentation/pages/agenda_event_detail_page.dart`

🚫 **Proibido alterar:**
- Lógica de negócio (eventos, calendário, dados)
- Providers de agenda
- Rotas de agenda
- Qualquer arquivo fora dos 3 listados

---

## 2. OBJETIVO

Eliminar uso de `pop()` e botão de voltar automático do AppBar nas 3 telas de agenda, adicionando `automaticallyImplyLeading: false` em todos os `AppBar`s e substituindo `context.pop()` / `Navigator.pop()` por `context.go('/agenda')` ou `context.go(AppRoutes.map)` onde apropriado.

---

## 3. REGRAS ABSOLUTAS

❌ `context.pop()` — PROIBIDO (substituir)
❌ `Navigator.pop(context)` — PROIBIDO (substituir)
❌ `context.canPop()` — PROIBIDO (remover lógica baseada nele)
✅ `context.go('/agenda')` — permitido para navegação entre telas de agenda
✅ `context.go(AppRoutes.map)` — permitido para retorno ao mapa
✅ `automaticallyImplyLeading: false` — obrigatório em todos os AppBars

---

## 4. AÇÕES POR ARQUIVO

### 4.1 `agenda_month_page.dart`

**Localizar o `AppBar` e adicionar:**
```dart
AppBar(
  automaticallyImplyLeading: false,  // ← ADICIONAR
  // ... demais propriedades inalteradas
),
```

Verificar se há chamadas `context.pop()` ou `Navigator.pop()` na página. Se houver:
- Se for retorno de navegação → substituir por `context.go('/agenda')` ou `context.go(AppRoutes.map)`
- Se for fechamento de Dialog/BottomSheet → **manter** (pop() é legítimo para modais)

### 4.2 `agenda_day_page.dart`

Mesma ação que 4.1: adicionar `automaticallyImplyLeading: false` ao AppBar.
Substituir qualquer `context.pop()` / `Navigator.pop()` de navegação por `context.go()` declarativo.

### 4.3 `agenda_event_detail_page.dart`

**Ação mais complexa — dois pontos de pop() explícito:**

**Ponto 1 (linha ~317):**
```dart
// ANTES
context.pop();

// DEPOIS — depende do contexto:
// Se está retornando para a lista de eventos do dia:
context.go('/agenda/day');  // ou rota equivalente com parâmetro de data
// Se não há rota intermédia clara:
context.go('/agenda');
```

**Ponto 2 (linha ~345):**
```dart
// ANTES
Navigator.pop(context, false);

// Verificar contexto: se é fechamento de um Dialog → manter Navigator.pop()
// Se é navegação de tela → substituir por context.go()
```

> **Regra de decisão:** `Navigator.pop(context, value)` com `value` retornando dado a um `showDialog`/`showModalBottomSheet` é **legítimo**. `Navigator.pop(context)` sem value para sair de uma tela de navegação é **proibido**.

**Adicionar `automaticallyImplyLeading: false` ao AppBar da tela.**

---

## 5. VERIFICAÇÃO DE `context.push()` nas páginas de agenda

O PRD menciona que `/agenda/day` e `/agenda/event/:id` podem ser navegados com `context.push()`, criando stack e permitindo pop() automático.

**Verificar no arquivo de rotas ou nas telas de origem:**
```bash
grep -r "context.push\|pushNamed" lib/modules/agenda/ --include="*.dart"
```

Se encontrado: reportar ao arquiteto — a mudança de `push()` para `go()` nos pontos de chamada pode ser necessária para garantir que o back automático nunca apareça. **Não alterar pontos de push() neste prompt** sem instrução explícita.

---

## 6. CONTRATO DE DADOS

Nenhuma entidade alterada. Nenhum provider alterado.
Mudanças são de navegação e layout de AppBar.

**Impacto retrocompatível:** SIM

---

## 7. VALIDAÇÃO FINAL

```bash
flutter analyze
```
Resultado esperado: **0 errors**

```bash
arch_check.sh
```
Resultado esperado: **Exit 0**

```bash
grep -r "context\.pop\(\)\|Navigator\.pop(context)" lib/modules/agenda/ --include="*.dart"
```
Resultado esperado: **zero** (exceto pop() dentro de showDialog/showModalBottomSheet — esses são legítimos)

---

## 8. CHECKLIST DE ENCERRAMENTO

- [ ] `agenda_month_page.dart`: `automaticallyImplyLeading: false` adicionado
- [ ] `agenda_day_page.dart`: `automaticallyImplyLeading: false` adicionado
- [ ] `agenda_event_detail_page.dart`: `automaticallyImplyLeading: false` adicionado
- [ ] `context.pop()` de navegação (linha ~317) substituído por `context.go()`
- [ ] `Navigator.pop(context, false)` (linha ~345) verificado — se modal → mantido; se navegação → substituído
- [ ] Nenhum `context.push()` alterado neste prompt
- [ ] `flutter analyze` → 0 errors
- [ ] `arch_check.sh` → Exit 0

**Dashboard alterado?** NÃO
**Outros módulos alterados?** NÃO
**Navegação mudou?** SIM — pop() → go() (intencional e documentado)
**Contrato alterado?** NÃO
**Apenas os 3 arquivos alvo foram afetados?** SIM

---

## 9. ENCERRAMENTO PADRÃO

O módulo `agenda/` foi corrigido: AppBars com `automaticallyImplyLeading: false` e pop() proibidos substituídos por navegação declarativa.
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
