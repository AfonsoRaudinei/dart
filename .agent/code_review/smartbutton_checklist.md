# ✅ Checklist de Code Review — SmartButton (FAB Global)

**Contrato:** Map-First  
**Componente:** `lib/ui/components/smart_button.dart`  
**Status:** OBRIGATÓRIO em TODO PR que toque navegação ou FAB

---

## ⚠️ VALIDAÇÃO OBRIGATÓRIA

Este checklist DEVE ser validado antes de aprovar qualquer Pull Request que:
- Modifique o SmartButton
- Altere navegação global
- Adicione novos FABs
- Modifique rotas ou fluxos de navegação

---

## 🔍 CHECKLIST (TODOS os itens devem ser ✅)

### 1. Unicidade do FAB
- [ ] **Existe apenas UM FAB no sistema?**
  - Verificar: Não existem outros `FloatingActionButton` fora de `SmartButton`
  - Verificar: Nenhuma tela cria FAB próprio

### 2. Detecção Determinística
- [ ] **O FAB depende SOMENTE da rota atual?**
  - Verificar: Uso de `AppRoutes.getLevel(uri)` ou equivalente
  - Verificar: NENHUMA consulta a stack de navegação
  - Verificar: NENHUMA lógica baseada em widget type
  - Verificar: NENHUM uso de flags globais ou estado persistido

### 3. Comportamento no `/map`
- [ ] **No /map, o FAB abre o SideMenu e NÃO navega?**
  ```dart
  // ✅ CORRETO
  case RouteLevel.l0:
    onPressed: () { Scaffold.of(context).openEndDrawer(); }
  
  // ❌ PROIBIDO
  case RouteLevel.l0:
    onPressed: () { context.go('/somewhere'); }
  ```

### 4. Comportamento Fora do `/map`
- [ ] **Fora do /map, o FAB executa EXCLUSIVAMENTE `context.go(AppRoutes.map)`?**
  ```dart
  // ✅ CORRETO
  case RouteLevel.l1:
  case RouteLevel.l2Plus:
    onPressed: () { context.go(AppRoutes.map); }
  
  // ❌ PROIBIDO
  onPressed: () { context.pop(); }
  onPressed: () { if (context.canPop()) ... }
  ```

### 5. Ausência de Navegação por Stack
- [ ] **Não existe NENHUM uso de:**
  - `Navigator.pop(context)` — ❌ PROIBIDO
  - `context.pop()` — ❌ PROIBIDO
  - `context.canPop()` — ❌ PROIBIDO
  - `context.maybePop()` — ❌ PROIBIDO
  - `Navigator.canPop(context)` — ❌ PROIBIDO

### 6. Ausência de Lógica Condicional Baseada em Stack
- [ ] **Nenhuma lógica depende de:**
  - Histórico de navegação
  - `ModalRoute.of(context)`
  - Contagem de rotas no stack
  - Widget type checking
  - Flags globais de navegação

### 7. Visibilidade Permanente
- [ ] **O FAB permanece SEMPRE visível?**
  - Verificar: Não há `Visibility(visible: false, ...)`
  - Verificar: Não há condicionais que escondem o FAB
  - Verificar: FAB presente em modo desenho, formulários, etc.

### 8. Ausência de Exceções por Tela
- [ ] **Não existem exceções por tela/módulo?**
  ```dart
  // ❌ PROIBIDO
  if (currentRoute == '/special-screen') {
    // comportamento diferente
  }
  ```

---

## ⚠️ DECISÃO DE APROVAÇÃO

### ✅ APROVAR SE:
- **TODOS** os 8 itens acima estão marcados como ✅
- Código alinhado com `docs/arquitetura-navegacao.md` (Seção 5)
- Testes automatizados passam

### 🚫 REJEITAR SE:
- **QUALQUER** item acima falhar
- Código introduz `pop()` ou `canPop()`
- Código cria múltiplos FABs
- Código cria exceções por tela

---

## 📚 Referências

- **Contrato:** `docs/arquitetura-navegacao.md` (Seção 5)
- **Implementação:** `lib/ui/components/smart_button.dart`
- **Testes:** `test/ui/components/smart_button_test.dart`

---

## 🔒 Status

**Este checklist é parte do contrato Map-First e NÃO pode ser modificado sem revisão arquitetural formal.**

Última atualização: 09/02/2026
