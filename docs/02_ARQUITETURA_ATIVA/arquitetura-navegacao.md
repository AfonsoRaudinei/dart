# CONTRATO ARQUITETURAL DE NAVEGAÇÃO - SOLOFORTE
**STATUS: CONTRATO CONGELADO**
**ÚLTIMA ATUALIZAÇÃO:** 09/02/2026 — Decisão Arquitetural MAP-FIRST


Este documento define a verdade absoluta sobre a navegação e estrutura UI do SoloForte.
Qualquer alteração neste documento exige uma revisão arquitetural explícita.

⚠️ **IMPORTANTE:** Este documento trabalha em conjunto com:
- `arquitetura-namespaces-rotas.md` (detecção de contexto por namespace)
- `arquitetura-persistencia.md` (offline-first)
- `arquitetura-ocorrencias.md` (eventos geoespaciais)

---


## 1. REGRA DE OURO (GOLDEN RULE)

> **"Rota descreve o estado do aplicativo, não apenas a tela."**
> **"O mapa é único. Os contextos nunca são."**

Nenhuma decisão de navegação, botão, rota ou fluxo pode ser tomada sem estar explicitamente alinhada com este documento.
Proibido improvisar "voltar", "home", ou "menus" fora deste padrão.

---

## 2. PRINCÍPIOS FUNDAMENTAIS

### 2.1. Map First (Mapa Primeiro)
* A tela principal do aplicativo é o **MAPA**.
* O aplicativo inicia no Mapa (após login).
* O "Home" é o Mapa.
* Sair de qualquer fluxo profundo deve, idealmente, retornar ao contexto do Mapa.

### 2.2. Sem AppBar (No AppBar)
* **NÃO** utilizamos a AppBar padrão do Material Design (`Scaffold(appBar: ...)`).
* O topo da tela é área do mapa ou overlays transparentes.
* Títulos e controles devem flutuar ou estar em BottomSheets/Cards.

### 2.3. One FAB (SmartButton)
* Existe apenas **UM** botão de ação flutuante principal na tela: o **SmartButton**.
* Localizado no canto inferior direito (fixo em todas as telas).
* **Comportamento Dinâmico:**
    * No Mapa (`/map`): Abre o MENU (ícone ☰)
    * Fora do Mapa: Retorna ao Mapa via `context.go('/map')` (ícone ←)
* **Proibições:**
    * ❌ Múltiplos FABs no sistema
    * ❌ Esconder o FAB em algum fluxo
    * ❌ Usar `pop()` para retornar ao mapa
* Ver Seção 5 para regras detalhadas e antipadrões.


### 2.4. SideMenu (Apenas no Mapa)
* O Menu Lateral (Drawer/SideMenu) é acessível **apenas** quando se está no Mapa (`/map`).

### 2.5. Hierarquia e Navegação de Retorno
* **Núcleo:** `/map` é o centro absoluto do sistema (Map-First)
* **Retorno obrigatório:** Qualquer rota fora de `/map` deve retornar **explicitamente** via `context.go('/map')`
* **Proibições:**
  * ❌ `Navigator.pop()` para retornar ao mapa
  * ❌ `context.canPop()` para decisão de navegação
  * ❌ Navegação baseada em histórico/stack
* **Exceção pública:** `/public-map` é isolado (não compartilha estado com `/map`)

---

## 3. ARQUITETURA DO MAPA (MAP-CENTRIC)

⚠️ **DECISÃO ARQUITETURAL (09/02/2026):** O namespace `/map` substituiu definitivamente `/dashboard` como namespace central.

O Mapa é o centro absoluto do sistema, representado por um único mapa físico (singleton), porém com múltiplos contextos funcionais.

### 3.1. Namespace Oficial
A rota canônica que representa o mapa é:
**`/map`**

### 3.2. ⛔ PROIBIÇÃO ABSOLUTA: Sub-rotas do Mapa

**AS ROTAS ABAIXO NÃO DEVEM EXISTIR:**
- `/map/mapa-tecnico` ❌
- `/map/clima-eventos` ❌
- `/map/ocorrencias` ❌
- `/map/publicacoes` ❌
- `/map/ndvi` ❌

**Motivo:** Não representam telas ou navegação. São apenas **modos, camadas e overlays** do mesmo mapa físico.

### 3.3. Modelo Correto: Estado Interno do Mapa

Estes contextos são **estado local do mapa**, controlados por contrato explícito:

```dart
enum MapContext {
  tecnico,
  clima,
  ocorrencias,
  publicacoes,
  ndvi,
}
```

**Regras:**
- Ícones acima do mapa alteram somente `MapContext`
- A URL permanece sempre `/map`
- Back button não altera contexto
- Estado pode ser persistido (offline-first)

### 3.4. Deep Link (Permitido de Forma Controlada)

Aceito somente na entrada:
```
/map?context=ocorrencias
/map?context=ndvi
```

- Lido apenas no bootstrap
- Define estado inicial
- Após inicialização, URL não governa comportamento

### 3.5. O Que É Proibido (Antipadrões)
* ❌ Criar sub-rotas para modos do mapa (`/map/mapa-tecnico`)
* ❌ Tratar ícones como navegação
* ❌ Inferir contexto do mapa via URL
* ❌ Usar `startsWith('/map/...')` para estado interno
* ❌ Basear contexto em widget visível ou variáveis globais
* ❌ Criar mapas paralelos fora do namespace `/map`
* ❌ Depender de histórico de navegação (`pop`, `canPop`)

---

## 4. ESTRUTURA DE NAVEGAÇÃO GERAL

A navegação é hierárquica e determinística.

### 4.1. Rota Raiz: `/` (Roteamento Técnico)

A rota raiz **NÃO renderiza UI**.

**Comportamento:**
- **Pré-login:** Redirect para `/public-map`
- **Pós-login:** Redirect para `/map`

**Características:**
- Apenas lógica de roteamento
- Decisão baseada em estado de autenticação
- Transparente para o usuário
- Não possui componente visual próprio

### 4.2. Rota Núcleo: `/map`
* Contém: Mapa (Singleton Widget), SmartButton (Modo Menu), Estado de Contexto Interno.

### 4.3. Exceção Pública: `/public-map`

**Classificação:** Exceção Arquitetural Controlada

**Características:**
- **Única exceção** de mapa fora do namespace `/map`
- **Isolamento total:** NÃO compartilha estado com `/map`
- **Sem `MapContext`:** Não possui contextos técnicos
- **Pré-login apenas:** Desativado após autenticação
- **Não evolui:** Não se transforma em mapa técnico

**Proibições:**
- ❌ Usar como referência para novos mapas
- ❌ Compartilhar lógica com `/map`
- ❌ Adicionar contextos técnicos
- ❌ Usar como padrão arquitetural

### 4.4. Fluxos Secundários (BottomSheets ou FullScreen)
* Telas de "Cadastro", "Listas", "Relatórios" navegam para fora do namespace `/map` ou abrem sobre ele.
* **Voltar:** Sempre navega explicitamente para `/map` (reset state) ou para a rota pai definida.

---

## 5. BOTÃO GLOBAL DE NAVEGAÇÃO (SMARTBUTTON / FAB)

O **SmartButton** é o **ÚNICO** botão de ação flutuante (FAB) do sistema.

Localização: **Canto inferior direito** (fixo em todas as telas)

### 5.1. Princípio de Ouro do FAB

> **"No mapa, o FAB governa o sistema."**  
> **"Fora do mapa, o FAB retorna ao mapa."**  
> **Nada além disso.**

### 5.2. Comportamento Canônico (OBRIGATÓRIO)

#### 🗺️ Quando a rota é `/map`

**Ícone:** ☰ (Menu / Hamburguer)

**Ação:** Abrir SideMenu (drawer lateral direito)

**Regras:**
- ✅ Executa `Scaffold.of(context).openEndDrawer()`
- ✅ Permanece visível durante desenho, ocorrências, etc.
- ❌ **NUNCA** executa navegação
- ❌ **NUNCA** vira botão "voltar"
- ❌ **NUNCA** muda para "salvar", "cancelar", etc.

---

#### ← Quando a rota NÃO é `/map`

**Ícone:** ← (Seta de retorno)

**Ação:** Retorno **explícito** para `/map` via navegação declarativa

**Regras:**
- ✅ Executa `context.go('/map')` ou `context.go(AppRoutes.map)`
- ✅ Funciona em **todas** as rotas fora do mapa:
  - `/consultoria/*` (relatórios, clientes, fazendas, talhões)
  - `/settings`
  - `/agenda`
  - `/feedback`
  - Qualquer outra rota autenticada

**Proibições absolutas:**
- ❌ `Navigator.pop(context)` — **PROIBIDO**
- ❌ `context.pop()` — **PROIBIDO**
- ❌ `context.canPop()` para decidir comportamento — **PROIBIDO**
- ❌ Navegação baseada em histórico/stack — **PROIBIDO**
- ❌ Retorno implícito ou heurístico — **PROIBIDO**

### 5.3. Regra de Detecção (Determinística)

O comportamento do FAB depende **exclusivamente** de:

```dart
final bool isMap = currentRoute == '/map';
// ou
final bool isMap = AppRoutes.getLevel(currentRoute) == RouteLevel.l0;
```

**E NUNCA de:**
- ❌ Stack de navegação (`canPop`, histórico)
- ❌ Widget visível na tela
- ❌ Tela específica por nome
- ❌ Estado interno do mapa (`MapContext`)
- ❌ Exceções pontuais por módulo

### 5.4. Antipadrões Proibidos

É **expressamente proibido**:

1. ❌ Criar FAB diferente por módulo ou tela
2. ❌ Esconder o FAB em algum fluxo (ele é âncora sistêmica)
3. ❌ Transformar o FAB em botão de ação contextual ("salvar", "cancelar", "confirmar")
4. ❌ Usar igualdade frouxa de rota sem contrato (`path.contains('/map')`)
5. ❌ Criar lógica especial para sub-contextos do mapa (clima, ocorrências, NDVI)
6. ❌ Duplicar FABs em telas específicas

### 5.5. Unicidade do FAB

**Existe apenas UM FAB no sistema.**

- Todos os módulos compartilham o mesmo FAB global
- Não existem FABs específicos por tela
- Não existem FABs adicionais ou complementares
- O SmartButton é o único FloatingActionButton do app

### 5.6. Justificativa Arquitetural

**Por que um único FAB?**
- Previsibilidade total de navegação
- Usuário sempre sabe como "voltar ao centro" (Map-First)
- Sem dependência de stack (navegação declarativa)
- Comportamento determinístico em qualquer cenário (hot restart, deep link, etc.)

**Por que não usar `pop()`?**
- Não depende de histórico de navegação
- Funciona corretamente após deep links
- Funciona após hot restart / app kill
- Garante retorno ao mapa independente do caminho percorrido

---

## 6. MODO DESENHO E EDIÇÃO GEOGRÁFICA

O **Modo Desenho** é um estado operacional do Mapa, não uma rota.

### 6.1. Princípio Fundamental
> **"Desenho é um modo de interação do mapa, não uma tela."**

* O mapa permanece o mesmo.
* A URL permanece sempre `/map`.
* O que muda: Ferramentas visíveis, comportamento de toque, overlays.

### 6.2. Interação com a Navegação
* **SmartButton:** Permanece exibindo o Menu (☰) se estiver no Mapa.
    * O botão **NÃO** muda para "Salvar" ou "Cancelar".
    * O botão **NÃO** executa `pop()`.
* **Cancelamento/Confirmação:** Devem ser ações explícitas na interface de desenho (botões dedicados na tela ou bottom sheet), nunca implícitas pela navegação.

### 6.3. Proibições (Antipadrões)
* ❌ Criar rotas como `/map/desenho` ou `/editor`.
* ❌ Usar o botão "Voltar" do Android/iOS para cancelar o desenho (o back button deve respeitar a hierarquia de navegação ou sair do app, não controlar estado local de widgets).
* ❌ Esconder o SmartButton durante o desenho (ele é âncora sistêmica).

---

## 7. PRINCÍPIO DE OURO (ATUALIZADO)

> **"Rota muda quando o usuário sai do mapa."**
> **"Ícones mudam quando o usuário muda o contexto do mapa."**
> **"/map substitui definitivamente /dashboard."**

---

## 8. REGRA PARA AGENTES (PROMPTS FUTUROS)

Para garantir a integridade deste contrato, todo prompt técnico deve conter:

> "Seguir rigorosamente `docs/arquitetura-navegacao.md`.
> O SoloForte possui um único mapa físico (singleton) na rota `/map`.
> Contextos do mapa são estado interno, NÃO sub-rotas.
> Se houver conflito, o documento prevalece."

**Agentes são instruídos a rejeitar solicitações que violem este contrato.**
