# CONTRATO ARQUITETURAL DE NAVEGAÇÃO - SOLOFROTE
**STATUS: CONTRATO CONGELADO**
**DATA:** 08/02/2026


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
* Localizado no canto inferior direito.
* **Comportamento Dinâmico:**
    * No Dashboard (Namespace `/dashboard`): Abre o MENU (ícone ☰).
    * Fora do Dashboard: Volta para o Dashboard (ícone ←).

### 2.4. SideMenu (Apenas no Mapa)
* O Menu Lateral (Drawer/SideMenu) é acessível **apenas** quando se está no Dashboard.

---

## 3. ARQUITETURA DO DASHBOARD (MAP-CENTRIC)

O Dashboard é o centro absoluto do sistema, representado por um único mapa físico, porém com múltiplos contextos funcionais.

### 3.1. Namespace Oficial
Todas as rotas que representam o mapa e seus contextos devem viver sob:
`/dashboard`

### 3.2. Sub-contextos Oficiais
As rotas representam **estados declarativos**, não apenas telas.
Exemplos oficiais:

* `/dashboard` → Container base (redirect para contexto padrão)
* `/dashboard/mapa-tecnico` → Contexto técnico (talhões, desenho, operações)
* `/dashboard/clima-eventos` → Contexto climático
* `/dashboard/ocorrencias` → Ocorrências e registros
* `/dashboard/publicacoes` → Marketing / publicações
* `/dashboard/ndvi` → Índices vegetativos (futuro)

**O mapa físico é o mesmo.** O que muda entre rotas:
* Camadas ativas
* Botões visíveis
* Permissões
* Overlays
* Comportamento de interação

### 3.3. O Que É Proibido (Antipadrões)
* ❌ Usar uma única rota `/dashboard` com `if (modo == X)`.
* ❌ Basear contexto em widget visível ou variáveis globais.
* ❌ Criar dashboards paralelos fora do namespace `/dashboard/*`.
* ❌ Depender de histórico de navegação (`pop`, `canPop`).

---

## 4. ESTRUTURA DE NAVEGAÇÃO GERAL

A navegação é hierárquica e determinística.

### 4.1. Rota Raiz: `/dashboard`
* Contém: Mapa (Singleton Widget), SmartButton (Modo Menu), Overlays de Contexto.

### 4.2. Fluxos Secundários (BottomSheets ou FullScreen)
* Telas de "Cadastro", "Listas", "Relatórios" navegam para fora do namespace `/dashboard` ou abrem sobre ele.
* **Voltar:** Sempre navega explicitamente para `/dashboard` (reset state) ou para a rota pai definida.

---

## 5. BOTÃO GLOBAL DE NAVEGAÇÃO (SMARTBUTTON)

### Comportamento Oficial
* **Rota inicia com `/dashboard`**:
  * Ícone: ☰ (Menu)
  * Ação: Abrir SideMenu
* **Rota NÃO inicia com `/dashboard`**:
  * Ícone: ← (Voltar)
  * Ação: `go('/dashboard')`

Esse comportamento depende exclusivamente do namespace da rota.

---

## 6. MODO DESENHO E EDIÇÃO GEOGRÁFICA

O **Modo Desenho** é um estado operacional do Dashboard, não uma rota.

### 6.1. Princípio Fundamental
> **"Desenho é um modo de interação do mapa, não uma tela."**

* O mapa permanece o mesmo.
* A URL permanece a mesma (ex: `/dashboard/mapa-tecnico`).
* O que muda: Ferramentas visíveis, comportamento de toque, overlays.

### 6.2. Interação com a Navegação
* **SmartButton:** Permanece exibindo o Menu (☰) se estiver no Dashboard.
    * O botão **NÃO** muda para "Salvar" ou "Cancelar".
    * O botão **NÃO** executa `pop()`.
* **Cancelamento/Confirmação:** Devem ser ações explícitas na interface de desenho (botões dedicados na tela ou bottom sheet), nunca implícitas pela navegação.

### 6.3. Proibições (Antipadrões)
* ❌ Criar rotas como `/dashboard/desenho` ou `/editor`.
* ❌ Usar o botão "Voltar" do Android/iOS para cancelar o desenho (o back button deve respeitar a hierarquia de navegação ou sair do app, não controlar estado local de widgets).
* ❌ Esconder o SmartButton durante o desenho (ele é âncora sistêmica).

---

## 7. REGRA PARA AGENTES (PROMPTS FUTUROS)

Para garantir a integridade deste contrato, todo prompt técnico deve conter:

> "Seguir rigorosamente `docs/arquitetura-navegacao.md`.
> O Soloforte possui um único mapa físico, mas múltiplos contextos via rotas `/dashboard/*`.
> Se houver conflito, o documento prevalece."

**Agentes são instruídos a rejeitar solicitações que violem este contrato.**
