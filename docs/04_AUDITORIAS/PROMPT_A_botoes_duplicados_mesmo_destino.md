# PROMPT — Grupo A: Remoção de Botões Duplicados (Mesmo Destino)

**Agente:** Engenheiro Sênior Flutter/Dart — Especialista em Clean Architecture Riverpod
**Tipo:** Correção Estrutural — Duplicidade de Navegação
**PRD Referência:** PRD_SMART_BUTTON_UNIFICACAO.md — Erros 2, 3, 6 — Prioridade 1 Crítica
**Branch:** release/v1.1

---

## 1. ESCOPO

**Módulos:** `planos/`, `feedback/`, `ui/screens`

**Arquivos tocados (apenas estes):**
- `lib/modules/planos/presentation/screens/planos_screen.dart`
- `lib/modules/planos/presentation/screens/meu_plano_screen.dart`
- `lib/ui/screens/publicacao_editor_screen.dart`
- `lib/modules/feedback/presentation/screens/feedback_screen.dart`

🚫 **Proibido alterar:**
- `app_shell.dart`, `smart_button.dart`
- Providers, rotas, tema
- Qualquer outro arquivo fora dos 4 listados

---

## 2. OBJETIVO

Remover botões de navegação locais que duplicam o SmartButton (mesmo destino `/map`) em 4 telas, e adicionar `SizedBox(height: kFabSafeArea)` ao fim de cada ScrollView/ListView que estiver faltando.

---

## 3. REGRAS ABSOLUTAS

❌ Não remover o layout/header completo — apenas o widget de botão de navegação
❌ Não alterar lógica de negócio, providers, ou textos das telas
✅ Cirúrgico: remover apenas o `GestureDetector`/`IconButton` de retorno e o espaço que ele ocupava no layout
✅ Adicionar `SizedBox(height: kFabSafeArea)` onde ausente

---

## 4. AÇÕES POR ARQUIVO

### 4.1 `planos_screen.dart`

**Localizar em `_buildHeader()`:**
```dart
GestureDetector(
  onTap: () {
    HapticFeedback.lightImpact();
    context.go('/map');
  },
  child: Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: Color(0xFF1C1C1E), ...),
    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF32D74B)),
  ),
),
```
**Ação:** Remover o `GestureDetector` inteiro (incluindo o `Container` filho).
**Se o header ficar vazio ou com layout quebrado:** Substituir o espaço por `const SizedBox(width: 40)` para manter alinhamento do título.

**Localizar o ListView/Column principal e adicionar ao fim:**
```dart
SizedBox(height: kFabSafeArea),
```

### 4.2 `meu_plano_screen.dart`

Mesma ação que 4.1: localizar e remover `GestureDetector` com `context.go('/map')` no header.
Adicionar `SizedBox(height: kFabSafeArea)` ao fim do scrollable.

### 4.3 `publicacao_editor_screen.dart`

**Localizar no `AppBar`:**
```dart
leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.go('/map'),
),
```
**Ação:** Remover apenas a propriedade `leading: ...` do `AppBar`. Manter o `AppBar` e todas as outras propriedades intactas.

Verificar se há `automaticallyImplyLeading` — se não houver, adicionar:
```dart
automaticallyImplyLeading: false,
```

### 4.4 `feedback_screen.dart`

**Localizar no body (linha ~66-70):**
```dart
IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.black),
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  onPressed: () => context.go(AppRoutes.map),
),
```
**Ação:** Remover o `IconButton` inteiro.
**Se ele estiver em uma `Row` de header:** remover o item da Row; se a Row ficar com apenas 1 item, avaliar se pode virar simples `Text` ou `Padding`.

**Adicionar ao fim do `SingleChildScrollView`:**
```dart
SizedBox(height: kFabSafeArea),
```

---

## 5. IMPORT CHECK

Verificar se após as remoções algum import fica sem uso:
- `HapticFeedback` em `planos_screen.dart` (se só era usado no botão removido → remover import)
- `AppRoutes` em `feedback_screen.dart` (verificar se ainda usado após remoção)

Remover imports órfãos para manter `flutter analyze` limpo.

---

## 6. CONTRATO DE DADOS

Nenhuma entidade alterada. Nenhum provider alterado. Mudanças são exclusivamente de UI/layout.

**Impacto retrocompatível:** SIM — remoção de widget, sem quebra de contratos.

---

## 7. VALIDAÇÃO FINAL

```bash
flutter analyze
```
Resultado esperado: **0 errors** (manter warnings/infos pré-existentes)

```bash
arch_check.sh
```
Resultado esperado: **Exit 0**

```bash
grep -r "FloatingActionButton\|arrow_back.*go.*map\|go.*map.*arrow_back" \
  lib/modules/planos lib/modules/feedback lib/ui/screens/publicacao_editor_screen.dart \
  --include="*.dart"
```
Resultado esperado: **zero ocorrências de botão de retorno duplicado**

---

## 8. CHECKLIST DE ENCERRAMENTO

- [ ] `planos_screen.dart`: GestureDetector de retorno removido
- [ ] `meu_plano_screen.dart`: GestureDetector de retorno removido
- [ ] `publicacao_editor_screen.dart`: AppBar `leading` removido + `automaticallyImplyLeading: false`
- [ ] `feedback_screen.dart`: IconButton de retorno removido
- [ ] `kFabSafeArea` adicionado ao fim dos scrollables em todos os 4 arquivos
- [ ] Imports órfãos removidos
- [ ] `flutter analyze` → 0 errors
- [ ] `arch_check.sh` → Exit 0

**Dashboard alterado?** NÃO
**Outros módulos alterados?** NÃO
**Navegação mudou?** NÃO (SmartButton continua cobrindo a função)
**Contrato alterado?** NÃO
**Apenas os 4 arquivos alvo foram afetados?** SIM

---

## 9. ENCERRAMENTO PADRÃO

Os botões de navegação duplicados (mesmo destino do SmartButton) foram removidos de `planos_screen`, `meu_plano_screen`, `publicacao_editor_screen` e `feedback_screen`.
Nenhum outro módulo, rota, estado ou contrato do SoloForte foi alterado.
