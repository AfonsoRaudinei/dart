# 🚀 Plano de Execução: Refatoração Visual iOS Premium (SoloForte)

Este documento detalha o plano passo a passo para converter o aplicativo SoloForte atual para o **Design System Premium iOS** definido em `design_soloforte.md`.

**Regra de Ouro:** **NENHUMA LÓGICA DE NEGÓCIO, ESTADO OU FLUXO SERÁ ALTERADA.** Este é um processo estritamente visual (Refatoração de UI/UX superficial), alterando apenas as árvores de widgets de apresentação, temas e estilos.

---

## 🎯 Fase 1: Fundação e Constantes Globais (O "Core" Visual)

Antes de tocar em qualquer tela, precisamos construir o alicerce no qual todas elas vão se apoiar.

*   **Passo 1.1: Criar o `theme_premium.dart` ou `design_tokens.dart`.**
    *   Centralizar todas as variáveis de cor exatas do documento (Ex: `Color brandGreen = const Color(0xFF34C759);`, `backgroundLight = const Color(0xFFF2F2F7);`).
    *   Definir os estilos globais de texto (`TextTheme`), com focos específicos no **Letter Spacing** (`letterSpacing: -0.4`, etc) e definindo a fonte global (como SF Pro, Inter ou Roboto configurada geometricamente).
*   **Passo 1.2: Ajustar o `MaterialApp` (ou `CupertinoApp`).**
    *   Injetar o novo `ThemeData` no arquivo principal (`main.dart`).
    *   Substituir as reações físicas globais: desativar o efeito `Splash` e `Highlight` (Sombra redonda aquática do Material) em todo o app definendo `splashColor: Colors.transparent` e `highlightColor: Colors.transparent`.
*   **Passo 1.3: Construção da "Biblioteca de Partes" (Módulo `ui/components/premium`).**
    *   Criar um widget `PremiumButton` (Pill, sem sombra dura, com *HapticFeedback* e opacidade em 60% no `onTapDown`).
    *   Criar um widget `PremiumGlassPanel` (`BackdropFilter` pesado com fundo translúcido para ser reutilizado em qualquer Bottom Sheet).
    *   Criar um widget `PremiumInsetListGroup` (Contêineres com borda arredondada `circular(12)` de fundo totalmente branco que segurarão os itens de configurações ou campos de texto).

---

## 🗺 Fase 2: A Experiência "Map-First" (A Tela Principal Core)

O mapa é o principal ator do SoloForte. Onde tiver componentes flutuando sobre ele, reestilizaremos para se tornarem etéreos e responsivos.

*   **Passo 2.1: Floating Action Buttons (Os Controles da Direita e Bússola/Local).**
    *   **Arquivo Alvo:** Onde vivem os Docks de localização e camadas (`private_map_screen.dart` / `floating_dock.dart` / `map_controls_overlay.dart`).
    *   **Ação Visual:** Trocar botões sólidos ou coloridos genéricos por um container com `PremiumGlassPanel` arredondado ao máximo (circular).
    *   **Sombra:** Adicionar a "Sombra de Dispersão iOS": Opacidade em 8%, blur de `32px`, offset massivo em baixo `Offset(0,10)`.
    *   **Haptics:** Injetar `HapticFeedback.selectionClick()` no `onPressed` de qualquer visualização de camada de mapa ou ação de centralizar localização.
*   **Passo 2.2: Elementos de Topo de Mapa (SearchBar / Filtros).**
    *   Se existir uma barra superior solta flutuando em cima do mapa, aplicar a mesma estética visual de Vidro Denso, com bordas contínuas perfeitas.

---

## 🏗 Fase 3: A Dança das "Bottom Sheets" e Modais Modulares

Quando os dados são carregados acima do mapa, precisamos do visual fluido onde a Bottom Sheet quase encobre a página e desliza majestosamente.

*   **Passo 3.1: O Modificador Global de Bottom Sheet.**
    *   Em todas as chamadas de funções como `showModalBottomSheet(...)` espalhadas pelo app.
    *   **Ação Visual:** Setar o `backgroundColor` para `Colors.transparent`. A tela do Modal original ficará responsável por pintar na arvore primária dela o fundo.
    *   **O Drag Handle:** Injetar no topo de todas as telas modais visuais (onde abrem formulários) um `Grabber Handle` retangular diminutivo que simboliza o arraste de fechamento (exigência visual massiva de app premium).
*   **Passo 3.2: Formulários e Relatórios Deslizantes (As "Inset-Grouped Lists").**
    *   **Arquivos Relacionados:** Formulários (Como as ocorrências no `OccurrenceSheet`, Telas de Visita Técnica, Desenho, Configurações de Camadas do Mapa).
    *   **Ação Visual:** Em vez de campos ocupando todo o meio da tela do modal, envelopá-los em caixas brancas (`Color(0xFFFFFFFF)`) isoladas com `circular(12)` de margens cinzas de fundo `(Color(0xFFF2F2F7))`. Campos divisores entre cada linha finos num tom invisível (`0.5px`, `#C5C5C7`).
*   **Passo 3.3: Ajustes de Títulos na Gaveta inferior.**
    *   Alterar a barra onde ficam os títulos centrais e botões de `X` (Cancelar) ou `Salvar`. O "Cancelar" e "Salvar" passam a não ser ícones soltos, mas textos (`TextButton` / `CupertinoButton`) elegantes usando a "Tint Color Sovereign" do Passos 1 e 2 no `FontWeight.w600`.

---

## 📝 Fase 4: Tipografia Limpa em "Dashboards" Secundários

Quaisquer telas de lista de clientes listando estatísticas, relatórios finais antes de preencher, etc.

*   **Passo 4.1: Telas fora do Mapa Mestre.**
    *   Arquivos como histórico, visualização de PDF final, listas gerais ou configurações do perfil do agrônomo.
    *   **Ação Visual:** Substituir as `AppBars` com sombra rígida do Material Design por uma navegação de topo perfeitamente limpa e borrada. A navegação funde-se perfeitamente na página a não ser que tenha Scroll por baixo. Quando dá Scroll na lista sob a AppBar, injeta `BackdropFilter` (Vidro e blur).
*   **Passo 4.2: Títulos Imponentes.**
    *   Adotar na árvore do `Scaffold` o padrão do título enorme jogado à extremidade da lateral esquerda para apresentar a sub-etapa `Text('Relatórios', style: Theme.of(context).textTheme.titleLarge)`.
*   **Passo 4.3: Ícones Modernizados.**
    *   Substituir ou reavaliar iconografia. Tudo que estiver preenchido com preenchimento forte será trocado por ícones "Outline" finos (Exemplo: trocar os ícones pesados de Material para um estilo fino SFSymbol-like / Cupertino). Ícones apenas enchem para sólido se forem a "aba selecionada principal" a qual o utilizador repousa a sua tela de navegação base.

---

## 🚦 Fase 5: Haptics e Polimento Final de Tatilidade (Toque Completo do Fluxo)

A fase de injeção física para o telefone agir. (Nenhuma lógica complexa altera o banco de dados).

*   **Passo 5.1: Vibração nas Toggles/Draw.**
    *   Arquivos ligados com a caneta de apontador / Ferramentas para de desenhar mapa manual / `Switch` Toggles on/off para exibir opções. Add `HapticFeedback.light()` no `OnChange`.
*   **Passo 5.2: Fim de Processo Massivo (A Vibração Pesada).**
    *   Arquivos que terminam envio massivo com Sucesso ou Delete ("Excluir Conta, Finalizar Report"). Incorporar o `HapticFeedback.medium()` seguido imediatamente que clica na ação, validando segurança na operação sensível do trabalhador agrícola na mão dele fisicamente antes da rede terminar o Call API ou salvamento banco local.

--- 

## ✅ Resumo / Status de Execução Esperado pela Engenharia

A mudança visual, embora complexa do ponto de vista atômico de Widget do Flutter, tem **impacto nulo** na persistência de dados (Controller / Riverpod / Repository), garantindo assim zero travamentos logísticos de uso e alta probabilidade de "Sucesso Imediato Visual". O sistema continuará fazendo exatamente o que faz hoje na camada negocial, porém passará de uma percepção estética "Bootstrap 2016" para um dos líderes visuais de Apps Agronômicos com percepção da silhueta Apple Hig.
