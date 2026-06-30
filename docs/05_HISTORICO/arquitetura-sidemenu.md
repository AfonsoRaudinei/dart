# CONTRATO ARQUITETURAL DO SIDEMENU — SOLOFORTE
**STATUS: CONTRATO CONGELADO**  
**DATA:** 08/02/2026

Este documento define a verdade absoluta sobre o SideMenu (Menu Lateral) do SoloForte.  
Qualquer alteração neste documento exige uma revisão arquitetural explícita.

⚠️ **IMPORTANTE:** Este documento trabalha em conjunto com:
- `arquitetura-navegacao.md` (contrato de navegação Map-First)
- `arquitetura-namespaces-rotas.md` (detecção de contexto por namespace)
- `indice-rotas.md` (índice canônico de rotas)

---

## 1. DEFINIÇÃO CANÔNICA

### 1.1. O Que É o SideMenu

O **SideMenu** (também chamado de Drawer ou Menu Lateral) é um **componente global de navegação secundária** do SoloForte.

**Características:**
- Componente único e global (singleton comportamental)
- Acessível através do SmartButton quando o ícone ☰ está ativo
- Posicionado à direita (`endDrawer` no Scaffold)
- Existência condicionada pelo namespace da rota atual

### 1.2. Papel Arquitetural

O SideMenu **NÃO** é o navegador principal do app.  
O **Dashboard (Mapa)** é o centro gravitacional.  
O SideMenu é uma **ferramenta de atalho** para navegar entre módulos sem sair do contexto visual do mapa.

---

## 2. REGRA DE DISPONIBILIDADE (NORMATIVA)

### 2.1. Disponibilidade por Namespace

O SideMenu é renderizado **exclusivamente** quando o usuário está autenticado.

Dentro do contexto autenticado, o SideMenu está **disponível em todas as rotas**.

**Implementação atual (AppShell):**
```dart
endDrawer: isAuth ? const SideMenu() : null,
```

**Significado:**
- Rota pública (`/public-map`, `/login`) → SideMenu **NÃO EXISTE**
- Rota autenticada (qualquer) → SideMenu **EXISTE** (mas só é acessível via SmartButton ☰)

### 2.2. Acessibilidade por Namespace

Embora o SideMenu exista em todas as rotas autenticadas, ele só é **acessível** quando o SmartButton mostra o ícone ☰.

**Regra de Acessibilidade:**
```
Se rota atual ∈ /dashboard/*
  → SmartButton mostra ☰
  → Usuário pode abrir SideMenu

Se rota atual ∉ /dashboard/*
  → SmartButton mostra ←
  → SideMenu não é acessível (botão não abre menu)
```

---

## 3. RELAÇÃO COM O SMARTBUTTON

### 3.1. Separação de Responsabilidades

| Componente | Responsabilidade |
|-----------|------------------|
| **SideMenu** | Renderizar o menu lateral com opções de navegação |
| **SmartButton** | Decidir quando mostrar ☰ (abre menu) ou ← (volta) |

### 3.2. Fluxo de Controle

1. **Usuário está em `/dashboard`**
   - `AppShell` renderiza `endDrawer: const SideMenu()`
   - `SmartButton` detecta namespace `/dashboard`
   - `SmartButton` exibe ícone ☰
   - Ao tocar ☰ → SideMenu é aberto

2. **Usuário está em `/consultoria/clientes`**
   - `AppShell` renderiza `endDrawer: const SideMenu()`
   - `SmartButton` detecta que **NÃO** é `/dashboard`
   - `SmartButton` exibe ícone ←
   - Ao tocar ← → Navega para `/dashboard` (menu não abre)

### 3.3. Comportamento Determinístico

A decisão de mostrar ☰ ou ← é **100% baseada no namespace da rota atual**, conforme definido em `arquitetura-namespaces-rotas.md`.

**Regra Técnica:**
```dart
final bool isDashboard =
    uri == AppRoutes.dashboard || uri.startsWith('${AppRoutes.dashboard}/');
```

---

## 4. CONTEÚDO DO SIDEMENU

### 4.1. Estrutura Fixa

O SideMenu possui **estrutura fixa** e não muda conforme a rota:

1. **Header Dinâmico**
   - Se rota ≠ `/dashboard` → Mostra botão "Voltar ao Mapa"
   - Se rota = `/dashboard` → Oculta botão

2. **Título Fixo**
   - "SoloForte" (branding)

3. **Menu Items Fixos**
   - Configurações (`/settings`)
   - Relatórios (`/consultoria/relatorios`)
   - Feedback (`/feedback`)
   - Agenda (`/agenda`)
   - Clientes (`/consultoria/clientes`)

### 4.2. Comportamento do Botão "Voltar ao Mapa"

O SideMenu implementa lógica interna para mostrar/ocultar o botão "Voltar ao Mapa":

**Regra Implementada:**
```dart
static bool shouldShowBackButton(String path) {
  const List<String> rootNamespaces = [
    '/dashboard',
    '/consultoria',
    '/solo-cultivares',
    '/gestao-agricola',
    '/marketing',
  ];
  
  if (rootNamespaces.contains(path)) {
    return false;  // Raiz de namespace → não mostra
  }
  
  return true;  // Sub-rota ou outra rota → mostra
}
```

**Tabela Verdade:**

| Rota | Mostra "Voltar ao Mapa"? |
|------|--------------------------|
| `/dashboard` | ❌ Não |
| `/dashboard/mapa-tecnico` | ✅ Sim |
| `/consultoria/relatorios` | ❌ Não (raiz do namespace) |
| `/consultoria/relatorios/123` | ✅ Sim (sub-rota) |
| `/settings` | ✅ Sim (fora de namespace raiz) |

---

## 5. PROIBIÇÕES EXPLÍCITAS (ANTIPADRÕES)

É expressamente proibido:

### ❌ 5.1. SideMenu Específico por Rota
Não criar múltiplos SideMenus ou versões condicionais.  
Existe **UM** SideMenu global.

### ❌ 5.2. Lógica Baseada em Stack
Não usar `Navigator.canPop()` ou histórico de navegação para decidir comportamento do menu.

### ❌ 5.3. Ícone Menu Fora do Dashboard
Não mostrar ☰ em rotas que não sejam `/dashboard/*`.  
O SmartButton já implementa essa regra.

### ❌ 5.4. Ocultar SideMenu por Módulo
Não remover o `endDrawer` condicionalmente por módulo.  
O SideMenu existe em todas as rotas autenticadas.

### ❌ 5.5. Navegação Imperativa
Usar sempre `context.go()` nos itens do menu, nunca `Navigator.push()`.

---

## 6. TABELA VERDADE COMPLETA

| Namespace | Rota Exemplo | SideMenu Existe? | SmartButton | Acessível? |
|-----------|--------------|------------------|-------------|------------|
| Público | `/public-map` | ❌ Não | CTA Login | ❌ |
| Público | `/login` | ❌ Não | CTA Login | ❌ |
| Dashboard | `/dashboard` | ✅ Sim | ☰ Menu | ✅ |
| Dashboard | `/dashboard/*` | ✅ Sim | ☰ Menu | ✅ |
| Consultoria | `/consultoria/*` | ✅ Sim | ← Voltar | ❌ |
| Settings | `/settings` | ✅ Sim | ← Voltar | ❌ |
| Agenda | `/agenda` | ✅ Sim | ← Voltar | ❌ |
| Feedback | `/feedback` | ✅ Sim | ← Voltar | ❌ |

---

## 7. GARANTIAS ARQUITETURAIS

Este contrato garante:

1. **Consistência Visual**
   - O menu nunca "desaparece" tecnicamente (sempre renderizado quando autenticado)
   - A acessibilidade é controlada pelo SmartButton

2. **Previsibilidade de Navegação**
   - Usuários sempre sabem que ☰ = Menu
   - Usuários sempre sabem que ← = Voltar ao Dashboard

3. **Escalabilidade**
   - Adicionar rotas `/dashboard/*` não quebra o menu
   - Adicionar namespaces não requer alterar o SideMenu

4. **Segurança de Estado**
   - Sem dependência de stack
   - Comportamento determinístico baseado em rota

5. **Facilidade de Auditoria**
   - Logs mostram namespace, não widgets
   - Testes podem validar por rota declarativa

---

## 8. ARQUIVOS DE IMPLEMENTAÇÃO

| Arquivo | Responsabilidade |
|---------|------------------|
| `lib/ui/components/app_shell.dart` | Renderiza `endDrawer: SideMenu()` |
| `lib/ui/components/side_menu.dart` | Implementa o menu e botão "Voltar ao Mapa" |
| `lib/ui/components/smart_button.dart` | Controla quando mostra ☰ ou ← |

---

## 9. REGRA PARA AGENTES (PROMPTS FUTUROS)

Para garantir a integridade deste contrato, todo prompt técnico deve conter:

> "Seguir rigorosamente `docs/arquitetura-sidemenu.md`.  
> O SideMenu é global e acessível apenas via SmartButton ☰ no namespace /dashboard.  
> Se houver conflito, o documento prevalece."

**Agentes são instruídos a rejeitar solicitações que violem este contrato.**

---

## 10. CONFORMIDADE COM OUTROS CONTRATOS

Este contrato está alinhado com:

- ✅ `arquitetura-navegacao.md` (Map-First, One FAB, No AppBar)
- ✅ `arquitetura-namespaces-rotas.md` (Detecção por namespace)
- ✅ `indice-rotas.md` (Rotas canônicas documentadas)

**Qualquer alteração neste contrato deve ser refletida nos documentos relacionados.**

---

**FIM DO CONTRATO DO SIDEMENU**
