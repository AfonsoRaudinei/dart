# CONTRATO ARQUITETURAL DE NAVEGAÇÃO
**STATUS: CONTRATO CONGELADO**
**DATA:** 04/02/2026

Este documento define a verdade absoluta sobre a navegação e estrutura UI do SoloForte.
Qualquer alteração neste documento exige uma revisão arquitetural explícita.

---

## 1. REGRA DE OURO (GOLDEN RULE)

> **Nenhuma decisão de navegação, botão, rota ou fluxo pode ser tomada sem estar explicitamente alinhada com este documento.**

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
* Títulos e controles devem flutuar ou estar em BottomSheets/Cards, nunca em uma barra sólida no topo que rouba espaço vertical.

### 2.3. One FAB (SmartButton)
* Existe apenas **UM** botão de ação flutuante principal na tela: o **SmartButton**.
* Localizado no canto inferior direito (padrão FAB).
* **Comportamento Dinâmico:**
    * No Mapa: Abre o MENU PRINCIPAL (ícone Menu Hambúrguer ou similar).
    * Em Sub-rotas/Formulários: Atua como ação primária ou contexto específico.
* **Proibido:** Adicionar múltiplos FABs espalhados pela tela.

### 2.4. SideMenu (Apenas no Mapa)
* O Menu Lateral (Drawer/SideMenu) é acessível **apenas** quando se está na rota raiz do Mapa.
* Não deve ser acessível via "swipe" em telas de detalhe para evitar conflitos de gestos.

---

## 3. ESTRUTURA DE NAVEGAÇÃO

A navegação é hierárquica, não baseada em abas (BottomNavigationBar está proibido como navegação primária).

### 3.1. Rota Raiz: `/dashboard/mapa-tecnico`
* Contém: Mapa, SmartButton (Modo Menu), Overlays de Status.

### 3.2. Fluxos Secundários (BottomSheets ou FullScreen)
* Devem ser chamados a partir do Mapa ou do Menu.
* Telas de "Cadastro", "Listas", "Relatórios" entram sobre o mapa ou navegam para uma nova tela cheia.
* **Voltar:** Deve sempre haver um mecanismo claro de "Voltar" (seja botão físico, gesto ou botão na UI customizada), levando de volta ao nível anterior (até chegar no Mapa).

---

## 4. REGRA PARA AGENTES (PROMPTS FUTUROS)

Para garantir a integridade deste contrato, todo prompt técnico submetido a um agente de deve conter a seguinte instrução:

> "Seguir rigorosamente `docs/arquitetura-navegacao.md`.
> Se houver conflito, o documento prevalece."

**Agentes são instruídos a rejeitar solicitações que violem este contrato.**

---

## Botão Global de Navegação (SmartButton)

O SoloForte adota um modelo de navegação **map-centric**, no qual o
Dashboard (`/dashboard`) representa o centro absoluto do sistema.

### Princípio Fundamental
O botão global de navegação **não utiliza histórico de navegação**.
Ele não executa `pop()` e não depende da stack do Navigator.

A navegação é **declarativa e determinística**, baseada exclusivamente
na rota atual.

### Comportamento Oficial

- Quando a rota ativa é `/dashboard`:
  - O botão exibe o ícone ☰ (menu)
  - A ação é abrir o SideMenu global

- Quando a rota ativa é qualquer outra:
  - O botão exibe o ícone ← (voltar)
  - A ação é navegar diretamente para `/dashboard`

Esse comportamento é obrigatório, inclusive em:
- Deep links
- Refresh de aplicação
- Rotas aninhadas profundas
- Fluxos encadeados entre módulos

### Restrições Técnicas

É expressamente proibido:
- Utilizar `Navigator.pop()`
- Utilizar `canPop()` ou lógica baseada em stack
- Implementar exceções por módulo ou submódulo
- Alterar o SideMenu com base na rota

### Justificativa Arquitetural

Em aplicativos GIS / agrícolas / operacionais:
- O mapa é o ponto de orientação cognitiva do usuário
- O acesso rápido e previsível ao mapa é crítico
- Navegação por histórico gera erros e confusão em campo

Esse padrão garante:
- Consistência de UX
- Redução de bugs
- Escalabilidade de módulos
- Facilidade de auditoria técnica
