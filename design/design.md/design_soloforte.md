# � SoloForte Design System: Premium iOS Architecture

Este documento define as diretrizes visuais e arquiteturais absolutas para o **SoloForte**. O objetivo é entregar uma experiência **Premium**, nativa e inconfundivelmente inspirada nos mais altos padrões de design da Apple (iOS Human Interface Guidelines), traduzidos para o Flutter.

A estética geral deve transmitir maturação, elegância espacial e física realista. O aplicativo não deve parecer um "site em um frame", mas sim uma ferramenta de alto nível, fluida e tátil.

---

## 1. 💎 A Filosofia Estética iOS Premium

O design premium iOS se apoia em três pilares fundamentais:
*   **Clareza e Espaço Negativo:** A interface nunca deve ser densa a ponto de sufocar. Margens generosas e uso massivo de espaço em branco (Negative Space) para guiar o olho naturalmente para o que importa. Menos bordas rígidas, mais alinhamento invisível.
*   **Profundidade e Materiais (Glassmorphism Reall):** Elementos sobrepostos ao mapa não usam cores sólidas e chapadas. Eles usam "Materiais" — camadas embaçadas (Blur pesado) que permitem que as cores vibrantes do mapa por baixo (lavouras, polígonos) "vazem" sutilmente, mantendo o contexto geográfico sempre presente e lindo.
*   **Gestos, Física e Tatilidade:** Nada reage duramente. Botões não apenas mudam de cor; eles respondem à física. Scroll tem o *bounce* elástico característico da Apple. Ações e transições disparam Haptics (vibrações sutis) precisos no dispositivo físico do usuário.

---

## 2. 🎨 Sistema de Cores e Materiais (Apple Native Feel)

Esqueça paletas de dezenas de cores super vibrantes. O modo Premium iOS usa fundos monocromáticos elegantes, onde a Cor Destaque (*Accent*) brilha como protagonista absoluta.

### Tint Color (A Cor Soberana da Ação)
No iOS, 90% das ações interativas na tela compartilham uma única cor central pulsante e elegante, que não compete com mais nada.
*   **SoloForte Tint/Primary (`CupertinoColors.systemGreen` modificado):** Um verde esmeralda profundo, fresco e super legível (`#34C759` para Light Mode, `#32D74B` vibrante para Dark Mode).
*   Esta cor é restrita a: Itens ativos na Tab Bar, Botões Primários, Switches ligados, e Texto Clicável (TextButtons). Jamais deve ser usada para fins decorativos.

### Espacialidade e Superfícies (O "Segredo" do Fundo)
Nunca usar "brancos" ou "pretos" nos painéis que flutuam sobre outros.
*   **Background Base (Light):** `#F2F2F7` (O clássico Cinza de Sistema agrupado do iOS). Elementos flutuantes, como Cards, serão `#FFFFFF`.
*   **Background Base (Dark):** `#000000` (Preto puro para o fundo do app, economiza bateria OLED).
*   **Superfície Elevada (Dark Cards):** `#1C1C1E` (Cinza escuro muito específico do iOS, que flutua elegantemente sobre o preto base).

### Materiais Transparentes e Vidro (Backdrop & Vibrancy)
A mágica da interface madura sobre mapas:
*   **Glass Padrão:** Onde houver uma Bottom Sheet, Navigation Bar ou Dock de FABs sobre o mapa: `Colors.white.withAlpha(200)` (ou equivalente `0xCCFFFFFF`) + **`BackdropFilter(blur: 24, sigmaX: 24, sigmaY: 24)`**.
*   A intenção é que um mapa verde vivo por baixo pareça embaçado de forma densa e luxuosa, e não apenas escurecido por uma cor preta translúcida fajuta.

---

## 3. ✍️ Tipografia: Sistema Preciso e Refinado

No padrão de prestígio, o tamanho da fonte não importa tanto quanto o **Kerning** (espaçamento entre letras) e o **Weight** (peso).
O Flutter deve ser configurado com `Typography`, idealmente mirando na **SF Pro Display / Text** (se licenciada/disponível), ou em `Inter` como um substituto espetacular de fonte geométrica com proporções suíças.

### Hierarquia de Peso
*   **Large Title (Display):** 34px | `FontWeight.w700` (Bold) | *Letter-Spacing: +0.37px*.
    (Títulos massivos escorados à esquerda que anunciam a página atual de forma imponente, padrão do menu "Ajustes" no iPhone).
*   **Title/Header Modal:** 17px | `FontWeight.w600` (SemiBold) | *Letter-Spacing: -0.4px*.
    (O título centralizado compacto em toda App Bar ou topo de uma Bottom Sheet).
*   **Body (Texto Corrido):** 17px | `FontWeight.w400` (Regular) | *Letter-Spacing: -0.4px* |  Cor variante entre Preto `#000` e Cinza Escuro `#3C3C43`.
*   **Callout/Meta:** 13px - 15px | `FontWeight.w500` | Cinza intermédio (Ex: O subtexto explicativo "Este talhão foi salvo ontem...").
*   **Caption (Labels de TabBar):** 10px - 11px | `FontWeight.w500` | *Letter-Spacing: +0.07px*.

---

## 4. 🔲 Formas e Componentes Contínuos (Squircles)

A Apple evita "cantos retos duros" ou raios simples. Eles usam curvas contínuas matematicamente perfeitas (chamadas de Squircles).

### Bottom Sheets (Cupertino Modal Pages)
A interação natural de quem visualiza relatórios por cima de um mapa.
*   Em vez de BottomSheets convencionais, o app pode disparar modais onde o *mapa inteiro no painel de trás se encolhe ligeiramente* (Scale down para `0.92`) e afunda, enquanto o painel com as informações sobe encobrindo 90% da tela, com as bordas superiores ultra arredondadas (`BorderRadius.circular(32)` ou maior).
*   **Hander / Drag Pill:** Todo painel flutuante tem uma pílula retangular no topo, ultra-suave (`5px` altura, `36px` largura, `#C5C5C7` arredondamento total `- circular(10)`).

### Botões Primários (Pill & Large)
*   Devem ocupar quase toda a extensão inferior da tela, grandes e imponentes: `Height: 56px` ou `50px`.
*   Formato: **Pill** (Totalmente arredondados nas laterais, como uma pílula `Radius.circular(50)`) ou **Cards Arredondados** elegantes (`Radius.circular(16)`).
*   **Efeito Físico "Cupertino":** Quando focado / apertado (TapDown), a tela inteira do botão NÃO FAZ Sombra "Material Ink Ripple" (aquele círculo que espalha água do Android). Ao invés disso, a opacidade do botão desce para `60%` num piscar de olhos, sem animações circulares, como um vidro pressionado fisicamente contra um LED. Implemente usando `CupertinoButton` internamente ou controle via `GestureDetector` ajustando Opacidade e `Transform.scale` sutil (diminui em -3% para dar a sensação que afundou).

### Listas Inset (Inset Grouped Lists)
Ao exibir formulários de registro de pragas ou relatórios no SoloForte, abrace as **Listas Agrupadas Internas** do iOS.
*   Em vez de campos preenchendo a tela toda, divida formulários em painéis brancos (`#FFFFFF`) com `borderRadius: 12`, inseridos elegantemente com uma grande margem cinza nas laterais (ex: 16px).
*   Divida as "linhas" do painel de configuração com simples traços horizontais acinzentados medindo incríveis 0.5px de espessura (não existe borda de lista forte no iOS, são divisores minúsculos).

---

## 5. 📳 Tatilidade Externa: Haptics Native Core

Um app maduro interage fisicamente com a mão do usuário, garantindo a fisicalidade mecânica que confirma qualquer ação agronômica importante do sistema:

1.  **Mudança de Tabs / Abrir BottomSheets:** Dispare silenciosamente `HapticFeedback.light()`. Confirma para as mãos que uma gaveta nova chegou sob os dedos.
2.  **Switches Analógicos e Snaps (Toggles):** O app tem opções de "Mostrar Câmeras", "Mostrar Doenças" — ativadas com botões "Switch" redondos? Ative `HapticFeedback.selectionClick()` ao cruzar o ponto médio.
3.  **Botões Principais de Salvar / Concluir Edição do Talhão:** Feedback pesado, uma massagem na sensação de finalidade de que foi gravado seguro. Acione `HapticFeedback.medium()`.
4.  **Erros Visíveis ou Exclusões Destrutivas:** Acione `HapticFeedback.heavy()` (vibração dura), acoplado possivelmente a um `Dialog` com botão vermelho de confirmação (CupertinoActionSheet).

---

## 6. 🖼 Sombras e Elevação (Sombras com Dispersão Agressiva)

O padrão iOS repudia sombras "duras, escuras e pequenas". As sombras iOS geram uma sensação de "flutuação pacífica".
*   Os `Floating Action Buttons` / Docks do mapa e Cards que flutuam devem ter sombras de uma amplitude massiva (com alta dispersão) e extrema baixeza opaca (super translúcidas).
*   **Exemplo Excelente:** `BoxShadow(color: Color.fromRGBO(0,0,0, 0.08), offset: Offset(0, 10), blurRadius: 32, spreadRadius: 0)`
*   Essas sombras empurram os cartões bem acima do mapa sem poluí-lo.

---

## � Resumo Operacional ao Programar o SoloForte:

O Desenvolvedor Flutter que entregar visual Mobile Premium deve validar com estes tópicos mentais:
1.  **Cadê o Vidro?** Eu bloqueei o meu mapa agronômico com um fundo cinzento ou botei um `BackdropFilter` denso para entregar relevo luxuoso à folha modal?
2.  **Tá Tremendo a Mão?** O HapticFeedback está atrelado às pressões de botões longos ou aberturas/fechamentos? Meu usuário sente o clique físico ou é apenas tela morta do Android antigo?
3.  **As Curvas são Grosseiras?** Eu coloquei botões com pontas e raios que cheiram a website (`circular 4`)? (Tudo tem que ser curvo, gordo natural e sofisticadamente liso: `circular 16+`, Listas e painéis com arredondamentos imensos de `24px` a `32px` nos modais superores).
4.  **Existe apenas UMA Cor Comandando?** Meu aplicativo está berrito de verde vibrante, azul roxo e amarelo alerta o tempo inteiro? Ou ele flui predominantemente branco/preto clean com Verde Premium surgindo SÓ ONDE o usuário OBRIGATORIAMENTE DEVE clicar/agir?
5.  **Letras Esmagadas?** A fonte no botão tem `letterSpacing` levemente reduzido com o peso `w600` parecendo sólida e resolvida para leitura rápida e limpa em luz solar máxima de fazenda?

Esta diretriz transforma um "aplicativo aceitável" em um "software líder de mercado inesquecível de se manusear". Simplicidade que é violentamente bem cuidada nos detalhes técnicos.
