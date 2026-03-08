# PRD — Unificação do Botão Global de Retorno ao Mapa
**Versão:** 1.0  
**Data:** 03/03/2026  
**Tipo:** Correção Estrutural — Nível Crítico  
**Branch:** release/v1.1  
**Autor:** Auditoria Técnica Automatizada (Engenheiro Sênior Flutter)

---

## 1. RESUMO EXECUTIVO

A auditoria identificou **5 problemas estruturais distintos** no sistema do botão global de navegação do SoloForte App. O componente `SmartButton` existe como implementação canônica, porém coexiste com múltiplos botões de navegação secundários espalhados por módulos, criando comportamento visual inconsistente, colisões de área de toque e risco de navegação incorreta.

---

## 2. ARQUITETURA ATUAL — DIAGNÓSTICO COMPLETO

### 2.1 Componente Canônico (Como Deveria Funcionar)

```
lib/ui/components/smart_button.dart       ← implementação canônica
lib/ui/components/app_shell.dart          ← shell que injeta o SmartButton
lib/core/router/app_routes.dart           ← classificação de nível de rota
```

**Contrato declarado no código:**

| Nível | Rota | Ícone | Ação |
|-------|------|-------|------|
| L0 | `/map` | ☰ hamburger | Abre SideMenu via Provider |
| L1/L2+ | Qualquer outra | ← arrow | `context.go(AppRoutes.map)` |
| PUBLIC | `/public-map`, `/login` | CTA | `context.go(AppRoutes.login)` |

**Posicionamento no `AppShell`:**
```dart
Positioned(
  bottom: 40,   // ← fixo, sem respeitar SafeArea do dispositivo
  right: 20,
  child: _SmartButtonWrapper(),
),
```

---

## 3. ERROS ESTRUTURAIS IDENTIFICADOS

---

### ❌ ERRO 1 — Sistema Paralelo Fantasma (`PrivateAppShell` + `FloatingMenuButton`)

**Arquivo:** `lib/ui/components/private_app_shell.dart`  
**Arquivo:** `lib/ui/components/map/floating_menu_button.dart`  
**Tipo:** Duplicidade de Arquitetura — Dead Code  
**Severidade:** ALTA

**Descrição:**  
Existe um sistema paralelo completo de botão de menu, composto por `PrivateAppShell` e `FloatingMenuButton`, que **nunca é instanciado em nenhum ponto do app**. O `PrivateAppShell` não é referenciado no roteador (`app_router.dart`) nem em nenhuma tela.

**Evidência:**
```dart
// private_app_shell.dart — classe definida, nunca usada no router
class PrivateAppShell extends StatelessWidget {
  final VoidCallback onMenuTap;  // ← requer callback externo (acoplamento)
  ...
  child: FloatingMenuButton(onTap: onMenuTap)  // ← sistema paralelo
}
```

**Bug crítico no `FloatingMenuButton`:**  
O widget `FloatingMenuButton` retorna um widget `Positioned` diretamente do seu `build()`:
```dart
// floating_menu_button.dart — linha ~47
return Positioned(   // ← BUG: Positioned fora de Stack é inválido
  bottom: MediaQuery.of(context).padding.bottom + 24,
  right: 16,
  child: ...
);
```

Ao mesmo tempo, o `PrivateAppShell` já envolve o botão em outro `Positioned`:
```dart
// private_app_shell.dart
Positioned(
  bottom: 0,
  right: 16,
  child: SafeArea(
    child: SizedBox(
      child: Center(child: FloatingMenuButton(...))  // ← Positioned dentro de Positioned
    ),
  ),
),
```

Isso cria um **`Positioned` aninhado fora de `Stack`** — o widget interno `Positioned` não tem Stack pai direto e seria renderizado como widget de largura/altura zero, causando crash ou layout silencioso quebrado.

**Impacto:** O `FloatingMenuButton` exibe o ícone de hamburger `SFIcons.menu` (idêntico visualmente ao SmartButton em L0), usando posicionamento diferente (`bottom: MediaQuery.padding.bottom + 24` vs `bottom: 40` do AppShell). Se este sistema fosse ativado, o botão apareceria em posição diferente do padrão.

---

### ❌ ERRO 2 — Módulo `planos/`: 4 Telas com Botão Duplicado

**Arquivos afetados:**
- `lib/modules/planos/presentation/screens/planos_screen.dart`
- `lib/modules/planos/presentation/screens/meu_plano_screen.dart`
- `lib/modules/planos/presentation/screens/pagamento_screen.dart`
- `lib/modules/planos/presentation/screens/indicacoes_screen.dart`

**Tipo:** Duplicidade de Botão de Navegação + Violação de Área Exclusiva  
**Severidade:** CRÍTICA

**Descrição:**  
Todas as 4 telas do módulo `planos/` implementam um botão de navegação próprio em `_buildHeader()` usando um `GestureDetector` com `Container` circular e `Icons.arrow_back_ios_new`. Como o `AppShell` envolve TODAS as rotas, o `SmartButton` é renderizado simultaneamente. Resultado: **dois botões de navegação coexistindo na mesma tela**.

**Evidência (`planos_screen.dart`):**
```dart
// Botão LOCAL no header (topo esquerdo)
GestureDetector(
  onTap: () {
    HapticFeedback.lightImpact();
    context.go('/map');  // ← navega para /map
  },
  child: Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: Color(0xFF1C1C1E), ...),
    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF32D74B)),
  ),
),

// + SmartButton renderizado pelo AppShell (canto inferior direito)
// → DOIS botões simultâneos
```

**Inconsistência de destino no módulo planos:**

| Tela | Rota | Classificação | SmartButton → Destino | Botão Local → Destino |
|------|------|---------------|----------------------|----------------------|
| PlanosScreen | `/planos` | L1 | `/map` | `/map` ✅ |
| MeuPlanoScreen | `/planos/meu-plano` | L1 | `/map` | `/map` ✅ |
| PagamentoScreen | `/planos/pagamento` | **L2+** | `/map` | `/planos` ❌ DIVERGÊNCIA |
| IndicacoesScreen | `/planos/indicacoes` | **L2+** | `/map` | `/planos` ❌ DIVERGÊNCIA |
| ConfirmacaoScreen | `/planos/confirmacao` | **L2+** | `/map` | `/planos/meu-plano` ❌ DIVERGÊNCIA |

**Nas 3 últimas telas**, o botão local leva para `/planos`, mas o SmartButton (L2+) leva para `/map`. O usuário tem dois botões com destinos DIFERENTES na mesma tela.

**Violação de Área Exclusiva:**  
O `Scaffold` dessas telas usa `SafeArea(bottom: true)` no corpo, com fundo preto `Color(0xFF000000)`, mas não reserva o espaço do SmartButton (`kFabSafeArea = 100px`). O conteúdo scrollável pode passar por baixo do SmartButton.

---

### ❌ ERRO 3 — `FeedbackScreen`: IconButton Manual Duplicando SmartButton

**Arquivo:** `lib/modules/feedback/presentation/screens/feedback_screen.dart`  
**Tipo:** Duplicidade de Botão de Navegação  
**Severidade:** ALTA

**Evidência:**
```dart
// feedback_screen.dart — linha 66-70
IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.black),
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  onPressed: () => context.go(AppRoutes.map),  // ← navega para /map
),
```

A tela ainda usa `Scaffold` + `SafeArea` sem `SizedBox(height: kFabSafeArea)` no fim do `SingleChildScrollView`. O conteúdo colide com o SmartButton.

O botão manual (`Icons.arrow_back`) está no topo esquerdo dentro do body. O SmartButton está no canto inferior direito. Dois pontos de toque com a mesma função.

---

### ❌ ERRO 4 — `ClientDetailScreen`: Botão Local com Destino Divergente

**Arquivo:** `lib/modules/consultoria/clients/presentation/screens/client_detail_screen.dart`  
**Tipo:** Divergência de Destino de Navegação  
**Severidade:** ALTA

**Evidência:**
```dart
// client_detail_screen.dart — linha 338-339
IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.go('/consultoria/clientes'),  // ← vai para lista de clientes
),
```

- Rota da tela: `/consultoria/clientes/:id` → classificado como **L2+**
- SmartButton (L2+): `context.go(AppRoutes.map)` → vai para `/map`
- Botão local: `context.go('/consultoria/clientes')` → vai para lista de clientes

**Dois botões de navegação com dois destinos diferentes**, criando confusão para o usuário: qual botão volta para a lista? Qual vai para o mapa?

---

### ❌ ERRO 5 — Módulo `agenda/`: AppBars com Leading Automático + SmartButton

**Arquivos afetados:**
- `lib/modules/agenda/presentation/pages/agenda_month_page.dart`
- `lib/modules/agenda/presentation/pages/agenda_day_page.dart`
- `lib/modules/agenda/presentation/pages/agenda_event_detail_page.dart`

**Tipo:** Scaffold Aninhado com AppBar Leading Automático  
**Severidade:** MÉDIA

**Descrição:**  
Todas as 3 telas de agenda usam `Scaffold` com `AppBar`. O GoRouter com `ShellRoute` já envolve o conteúdo no `AppShell` (que contém o SmartButton). Quando o router navega para `/agenda` via `context.go()`, o GoRouter NÃO adiciona uma rota no stack de `Navigator`, então `AppBar.leading` automaticamente **não** renderiza botão de voltar (pois `canPop()` retorna false para rotas navegadas com `go()`).

No entanto, para `/agenda/day` e `/agenda/event/:id` (navegados com `context.push()`), o `canPop()` retorna `true`, e o `AppBar` **renderiza automaticamente um botão de voltar** com comportamento de `context.pop()`. Isso:

1. Usa `context.pop()` — proibido pelo contrato do SmartButton
2. Navega para a rota anterior no stack (possivelmente `/agenda`), não para `/map`
3. Cria dois botões de retorno simultâneos: AppBar leading (topo esquerdo) + SmartButton (inferior direito)

**Evidência em `agenda_event_detail_page.dart`:**
```dart
// linha 317
context.pop();  // ← uso explícito de pop()

// linha 345
onPressed: () => Navigator.pop(context, false),  // ← Navigator.pop() proibido
```

---

### ❌ ERRO 6 — `PublicacaoEditorScreen`: AppBar com Leading Manual

**Arquivo:** `lib/ui/screens/publicacao_editor_screen.dart`  
**Tipo:** AppBar Leading Duplicando SmartButton  
**Severidade:** MÉDIA

**Evidência:**
```dart
// linha 77-79
leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.go('/map'),  // ← correto, mas duplicado
),
```

A tela usa `AppBar` com `leading` manual e ainda tem o SmartButton do AppShell. Dois botões, mesmo destino.

---

### ❌ ERRO 7 — SmartButton sem SafeArea Dinâmica

**Arquivo:** `lib/ui/components/app_shell.dart`  
**Tipo:** Posicionamento Frágil  
**Severidade:** MÉDIA

**Evidência:**
```dart
// app_shell.dart
Positioned(
  bottom: 40,  // ← valor fixo hardcoded
  right: 20,
  child: _SmartButtonWrapper(),
),
```

O `AppShell` usa `bottom: 40` hardcoded sem envolver o botão em `SafeArea`. Em dispositivos com `MediaQuery.padding.bottom > 0` (ex: iPhone com barra home = 34px), o botão fica em `40px` a partir da borda física, que pode colidir com a barra de sistema.

Por comparação, `FloatingMenuButton` (no sistema paralelo) usa:
```dart
bottom: MediaQuery.of(context).padding.bottom + 24,  // ← mais correto
```

A constante `kFabBottomMargin = 40.0` existe em `layout_constants.dart` mas não é usada no `AppShell`. O `AppShell` usa o valor literal `40` sem referência à constante.

---

### ❌ ERRO 8 — `MapControlsOverlay`: FABs em Modo Desenho sem heroTag Único Garantido

**Arquivo:** `lib/ui/components/map/widgets/map_controls_overlay.dart`  
**Tipo:** Conflito Potencial de heroTag  
**Severidade:** BAIXA

**Evidência:**
```dart
// map_controls_overlay.dart — linhas 255-265
FloatingActionButton(
  heroTag: 'complete_drawing_overlay',
  backgroundColor: PremiumTokens.brandGreen,
  onPressed: widget.onFinishDrawing,
),
FloatingActionButton(
  heroTag: 'cancel_drawing_overlay',
  backgroundColor: Colors.redAccent,
  onPressed: widget.onCancelDrawing,
),
```

Quando o modo desenho está ativo, estes dois FABs são renderizados na tela ao mesmo tempo que o `SmartButton` (que tem `heroTag: 'smart_button_back'` ou `'smart_button_menu'`). O Flutter não aceita múltiplos FABs com o mesmo `heroTag` na mesma árvore de widget — e embora os tags sejam distintos aqui, a presença de FABs dentro de um `Stack` posicionado em `bottom: 120, right: 16` cria três botões flutuantes simultâneos na zona inferior direita da tela.

---

## 4. MAPEAMENTO COMPLETO DOS BOTÕES ENCONTRADOS

| # | Componente | Arquivo | Posição | Ícone | Destino | Status |
|---|-----------|---------|---------|-------|---------|--------|
| 1 | `SmartButton` (L0) | `smart_button.dart` | ↘ bottom:40, right:20 | ☰ hamburger | SideMenu | ✅ Canônico |
| 2 | `SmartButton` (L1/L2+) | `smart_button.dart` | ↘ bottom:40, right:20 | ← arrow | `/map` | ✅ Canônico |
| 3 | `FloatingMenuButton` | `floating_menu_button.dart` | ↘ (nunca renderizado) | ☰ hamburger | callback | ❌ Fantasma |
| 4 | Header btn `planos_screen` | `planos_screen.dart` | ↖ topo esquerdo header | ← arrow_back_ios | `/map` | ❌ Duplicata |
| 5 | Header btn `meu_plano_screen` | `meu_plano_screen.dart` | ↖ topo esquerdo header | ← arrow_back_ios | `/map` | ❌ Duplicata |
| 6 | Header btn `pagamento_screen` | `pagamento_screen.dart` | ↖ topo esquerdo header | ← arrow_back_ios | `/planos` | ❌ Duplicata + destino errado |
| 7 | Header btn `indicacoes_screen` | `indicacoes_screen.dart` | ↖ topo esquerdo header | ← arrow_back_ios | `/planos` | ❌ Duplicata + destino errado |
| 8 | Header btn `confirmacao_screen` | `confirmacao_screen.dart` | ↖ topo esquerdo header | ← arrow_back_ios | `/planos/meu-plano` | ❌ Duplicata + destino errado |
| 9 | IconButton `feedback_screen` | `feedback_screen.dart` | corpo, topo | ← arrow_back | `/map` | ❌ Duplicata |
| 10 | IconButton `client_detail` | `client_detail_screen.dart` | corpo, topo | ← arrow_back | `/consultoria/clientes` | ❌ Destino divergente |
| 11 | AppBar leading `agenda_month` | `agenda_month_page.dart` | AppBar leading | (automático Flutter) | `context.pop()` | ❌ pop() proibido |
| 12 | AppBar leading `agenda_day` | `agenda_day_page.dart` | AppBar leading | (automático Flutter) | `context.pop()` | ❌ pop() proibido |
| 13 | AppBar leading `agenda_event` | `agenda_event_detail_page.dart` | AppBar leading | (automático Flutter) | `context.pop()` | ❌ pop() proibido |
| 14 | AppBar leading `publicacao_editor` | `publicacao_editor_screen.dart` | AppBar leading | ← arrow_back | `/map` | ❌ Duplicata |
| 15 | FAB `complete_drawing_overlay` | `map_controls_overlay.dart` | ↘ bottom:120, right:16 | ✓ check | onFinishDrawing | ⚠ Aceitável (funcional diferente) |
| 16 | FAB `cancel_drawing_overlay` | `map_controls_overlay.dart` | ↘ bottom:120, right:16 | ✗ close | onCancelDrawing | ⚠ Aceitável (funcional diferente) |

**Total de implementações encontradas:** 16 pontos de código com botões de navegação  
**Implementações não canônicas:** 14  
**Implementações com destino divergente:** 5  
**Implementações com `pop()` proibido:** 4+  

---

## 5. ANÁLISE DE CONFLITOS POR CATEGORIA

### 5.1 Conflito de Layout (Visual)

**Telas com dois botões simultâneos visíveis:**
- `PlanosScreen` → SmartButton (↘) + botão header (↖)
- `MeuPlanoScreen` → SmartButton (↘) + botão header (↖)
- `PagamentoScreen` → SmartButton (↘) + botão header (↖)
- `IndicacoesScreen` → SmartButton (↘) + botão header (↖)
- `FeedbackScreen` → SmartButton (↘) + IconButton (body top)
- `ClientDetailScreen` → SmartButton (↘) + IconButton (body top)
- `PublicacaoEditorScreen` → SmartButton (↘) + AppBar leading (↖)
- `AgendaMonthPage` → SmartButton (↘) + AppBar leading (↖, nas navegações com push)
- `AgendaDayPage` → SmartButton (↘) + AppBar leading (↖)
- `AgendaEventDetailPage` → SmartButton (↘) + AppBar leading (↖)

### 5.2 Conflito de Navegação (Destinos Divergentes)

**Destinos diferentes para botão local vs SmartButton:**

| Tela | SmartButton Destino | Botão Local Destino | Risco |
|------|--------------------|--------------------|-------|
| `PagamentoScreen` | `/map` | `/planos` | Usuário perde contexto |
| `IndicacoesScreen` | `/map` | `/planos` | Usuário perde contexto |
| `ConfirmacaoScreen` | `/map` | `/planos/meu-plano` | Fluxo de compra quebrado |
| `ClientDetailScreen` | `/map` | `/consultoria/clientes` | UX inconsistente |
| `AgendaEventDetailPage` | `/map` | `pop()` → rota anterior | Comportamento imprevisível |

### 5.3 Conflito com SafeArea / Área Exclusiva

**Telas sem reserva de espaço para o SmartButton (`kFabSafeArea = 100px`):**

```
FeedbackScreen      → SingleChildScrollView sem padding bottom
ClientDetailScreen  → ListView sem padding bottom declarado
AgendaMonthPage     → ListView sem kFabSafeArea
AgendaDayPage       → ✅ usa kFabSafeArea (padding: EdgeInsets.only(bottom: kFabSafeArea))
PlanosScreen        → ListView sem kFabSafeArea (fundo preto cobre botão)
MeuPlanoScreen      → Sem reserva explícita
PagamentoScreen     → ListView sem kFabSafeArea
IndicacoesScreen    → Sem reserva explícita
```

### 5.4 Uso de `pop()` Proibido

```
agenda_event_detail_page.dart:317  → context.pop()
agenda_event_detail_page.dart:345  → Navigator.pop(context, false)
AppBar automático (agenda_month, agenda_day, agenda_event) → pop() implícito
```

---

## 6. CAUSA RAIZ

O sistema foi projetado com a arquitetura correta (`SmartButton` global via `AppShell`), mas o módulo `planos/` foi desenvolvido com estética **iOS dark (ADR-012)** que usa padrão de header customizado com botão no topo esquerdo, **ignorando que o `AppShell` já provê o SmartButton**. Esse padrão foi replicado sem verificação do contrato.

Secundariamente, os módulos de `agenda/` e telas legadas (`feedback`, `client_detail`, `publicacao_editor`) mantiveram ou adicionaram botões locais que **não foram removidos quando o SmartButton foi implementado como padrão global**.

A existência do `PrivateAppShell` e `FloatingMenuButton` como dead code indica uma **tentativa de refatoração incompleta** — o sistema antigo foi substituído pelo AppShell/SmartButton, mas os arquivos antigos não foram deletados.

---

## 7. ESTRATÉGIA DE UNIFICAÇÃO

### Princípio Guia

> **"Um botão, uma posição, uma ação."**  
> O SmartButton é o único mecanismo de navegação de retorno ao mapa.  
> Cada tela deve confiar no SmartButton e não duplicar navegação.

### Regra de Ouro para `planos/`

Os módulos com estética customizada (dark/iOS) devem remover o `_buildHeader()` com botão local e utilizar título de tela conforme padrão de cada módulo, sem botão de navegação no corpo da tela.

**Exceção permitida:** Botões com ação **diferente** de retorno ao mapa são permitidos (ex: botão "Editar", "Salvar"). Apenas botões que **duplicam** a função de retorno devem ser removidos.

### Regra para `agenda/`

As telas de agenda devem remover o `AppBar` ou substituir por um `SliverAppBar` **sem** back button automático (`automaticallyImplyLeading: false`). O SmartButton cobre 100% da função de retorno.

### Regra de SafeArea do SmartButton

O `AppShell` deve usar `SafeArea` dinâmica ou `MediaQuery.padding.bottom` para posicionar o SmartButton, não um valor fixo `bottom: 40`.

---

## 8. DEFINIÇÃO ARQUITETURAL DEFINITIVA (Padrão Único Global)

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTRATO SmartButton v2                       │
├─────────────────────────────────────────────────────────────────┤
│ POSIÇÃO: Canto inferior direito                                  │
│          Positioned(                                             │
│            bottom: MediaQuery.of(context).padding.bottom + 16,  │
│            right: 16,                                            │
│          )                                                       │
├─────────────────────────────────────────────────────────────────┤
│ ÁREA EXCLUSIVA: 100px da base da tela                            │
│   = kFabHeight(56) + kFabBottomMargin(40) + kFabContentClear(4) │
│   Todo conteúdo scrollável DEVE terminar antes desta faixa       │
│   via: SizedBox(height: kFabSafeArea) ou padding bottom          │
├─────────────────────────────────────────────────────────────────┤
│ AÇÃO: context.go(AppRoutes.map) — SEMPRE determinístico          │
│   ❌ NÃO usa: Navigator.pop(), context.pop(), pop implícito AppBar│
├─────────────────────────────────────────────────────────────────┤
│ UNICIDADE: SOMENTE o SmartButton existe como botão de retorno    │
│   ❌ Nenhum módulo deve ter botão de retorno no corpo ou AppBar   │
│   ❌ Títulos de tela não devem ter botão de voltar acoplado       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. ARQUIVOS A MODIFICAR

### Grupo A — Remoção de Botão Duplicado + Mesmo Destino

| Arquivo | Ação | Complexidade |
|---------|------|--------------|
| `planos_screen.dart` | Remover `GestureDetector` + `Container` do `_buildHeader()` | Baixa |
| `meu_plano_screen.dart` | Remover `GestureDetector` + `Container` do `_buildHeader()` | Baixa |
| `feedback_screen.dart` | Remover `IconButton` de retorno do body | Baixa |
| `publicacao_editor_screen.dart` | Remover `leading: IconButton` do AppBar | Baixa |

### Grupo B — Remoção de Botão Duplicado + Destino Divergente (Requer Análise de UX)

| Arquivo | Ação | Observação |
|---------|------|------------|
| `pagamento_screen.dart` | Remover botão de header | SmartButton assume função de retorno |
| `indicacoes_screen.dart` | Remover botão de header | SmartButton assume função de retorno |
| `confirmacao_screen.dart` | Remover botão de header | **Revisar UX: usuário no fluxo de compra** |
| `client_detail_screen.dart` | Remover `IconButton(arrow_back)` | SmartButton vai para `/map`; navegação para lista perde-se |

> ⚠️ **Atenção `client_detail_screen.dart`:** O botão local vai para `/consultoria/clientes` (lista de clientes), comportamento útil para o usuário. A remoção deve ser acompanhada de análise se o SmartButton (que vai para `/map`) é suficiente, ou se deve haver um botão "Voltar para Lista" separado com estilo não conflitante.

### Grupo C — Refatoração de AppBar (Agenda)

| Arquivo | Ação | Complexidade |
|---------|------|--------------|
| `agenda_month_page.dart` | Adicionar `automaticallyImplyLeading: false` ao AppBar | Baixa |
| `agenda_day_page.dart` | Adicionar `automaticallyImplyLeading: false` ao AppBar | Baixa |
| `agenda_event_detail_page.dart` | Remover `context.pop()` e `Navigator.pop()` explícitos; adicionar `automaticallyImplyLeading: false` | Média |

### Grupo D — Reserva de Área Exclusiva (kFabSafeArea)

| Arquivo | Ação |
|---------|------|
| `feedback_screen.dart` | Adicionar `SizedBox(height: kFabSafeArea)` ao fim do ScrollView |
| `planos_screen.dart` | Adicionar `SizedBox(height: kFabSafeArea)` ao fim do ListView |
| `meu_plano_screen.dart` | Adicionar `SizedBox(height: kFabSafeArea)` |
| `pagamento_screen.dart` | Adicionar `SizedBox(height: kFabSafeArea)` |
| `indicacoes_screen.dart` | Adicionar `SizedBox(height: kFabSafeArea)` |
| `client_detail_screen.dart` | Adicionar padding `kFabSafeArea` ao ScrollView |
| `agenda_month_page.dart` | Já usa `kFabSafeArea`? → confirmar |

### Grupo E — Correção do AppShell (SafeArea)

| Arquivo | Ação |
|---------|------|
| `app_shell.dart` | Substituir `bottom: 40` por `MediaQuery.of(context).padding.bottom + 16` ou usar `SafeArea` |

### Grupo F — Remoção de Dead Code

| Arquivo | Ação |
|---------|------|
| `private_app_shell.dart` | **Deletar** (nunca usado, sistema paralelo fantasma) |
| `floating_menu_button.dart` | **Deletar** (nunca usado, tem bug crítico de Positioned) |

---

## 10. CHECKLIST PÓS-CORREÇÃO

- [ ] **Apenas 1 implementação** do botão de retorno ao mapa em toda a codebase
- [ ] SmartButton **sempre no canto inferior direito** em todas as telas autenticadas
- [ ] SmartButton **sempre navega para `/map`** via `context.go(AppRoutes.map)` determinístico
- [ ] **Área inferior exclusiva garantida**: `kFabSafeArea = 100px` respeitado em todas as telas
- [ ] **Nenhum `pop()` residual** para navegação de retorno (exceto Dialogs e BottomSheets legítimos)
- [ ] **Nenhum conflito com SafeArea**: SmartButton usa `MediaQuery.padding.bottom + 16` dinâmico
- [ ] **Nenhum Scaffold duplicado**: `AppShell` é o único Scaffold raiz (Scaffolds filhos não devem ter FAB)
- [ ] `PrivateAppShell` e `FloatingMenuButton` **deletados**
- [ ] Módulo `planos/`: **zero botão de header** com função de retorno
- [ ] Módulo `agenda/`: **`automaticallyImplyLeading: false`** em todos os AppBars
- [ ] `FeedbackScreen`: **botão de retorno no body removido**
- [ ] `PublicacaoEditorScreen`: **AppBar leading removido**
- [ ] `ClientDetailScreen`: **decisão documentada** sobre botão de "Voltar à Lista"
- [ ] AppShell `bottom: 40` → **`MediaQuery.padding.bottom + 16`**
- [ ] `layout_constants.dart` `kFabBottomMargin = 40` → **verificar consistência** com nova fórmula

---

## 11. RISCO DE REGRESSÃO

| Área | Risco | Mitigação |
|------|-------|-----------|
| Fluxo de compra `planos/` | Usuário em `/planos/pagamento` perde botão de voltar para `/planos` | SmartButton vai para `/map`; usuário pode reentrar no fluxo |
| `ClientDetailScreen` | Remoção do botão para lista pode quebrar UX de navegação contextual | Criar botão "← Clientes" no título, sem função de retorno ao mapa |
| `AgendaEventDetailPage` | `context.pop()` explícito nos botões de ação do evento | Substituir por `context.go('/agenda')` determinístico |
| Testes automatizados | Testes que verificam presença de AppBar back button falharão | Atualizar testes após mudanças |

---

## 12. PRIORIDADE DE IMPLEMENTAÇÃO

```
Prioridade 1 (CRÍTICA — Sem regressão de UX):
  → Grupo F: Deletar dead code (private_app_shell + floating_menu_button)
  → Grupo E: Corrigir SafeArea do AppShell
  → Grupo A: Remover botões duplicados com mesmo destino (planos L1, feedback, publicacao_editor)

Prioridade 2 (ALTA — Com análise de UX):
  → Grupo B: Remover botões com destino divergente (pagamento, indicacoes, confirmacao)
  → Grupo C: Refatorar AppBars do módulo agenda

Prioridade 3 (MÉDIA — UX complexo):
  → client_detail_screen: decisão arquitetural sobre navegação contextual
  → Grupo D: Garantia de área exclusiva em todas as telas
```

---

*Documento gerado por auditoria técnica automatizada em 03/03/2026.*  
*Nenhuma alteração de código foi realizada durante a auditoria.*
