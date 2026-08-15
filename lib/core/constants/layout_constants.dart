/// ════════════════════════════════════════════════════════════════════
/// LAYOUT CONSTANTS — SOLOFORTE
/// ════════════════════════════════════════════════════════════════════
///
/// Constantes de layout compartilhadas entre todos os módulos.
/// Qualquer valor de posicionamento ou padding que precisa ser
/// consistente no sistema inteiro deve ser definido aqui.
///
/// REGRA: Nunca hard-code valores de padding/margin que dependem
/// do SmartButton. Use sempre [kFabSafeArea] (+ safe-area do device).
/// ════════════════════════════════════════════════════════════════════
library;

/// Altura padrão do FloatingActionButton (Material Design).
const double kFabHeight = 56.0;

/// Inset do SmartButton acima da safe-area bottom no AppShell.
/// Corresponde a `Positioned(bottom: MediaQuery.padding.bottom + 16)`.
const double kFabShellBottomInset = 16.0;

/// @Deprecated Use [kFabShellBottomInset]. Mantido como alias.
const double kFabBottomMargin = kFabShellBottomInset;

/// Margem de conforto acima do FAB para que o conteúdo não fique
/// visualmente colado ao botão.
const double kFabContentClearance = 4.0;

/// Altura reservada para o SmartButton *acima* da safe-area do device.
///
/// Composição:
///   56dp  — altura do FAB
///   16dp  — inset AppShell acima da safe-area
///    4dp  — clearance visual
/// ─────────
///   76dp  total acima de `MediaQuery.padding.bottom`
///
/// Uso edge-to-edge (mapa, listas full-bleed):
/// ```dart
/// padding: EdgeInsets.only(bottom: context.fabSafeBottomPadding),
/// // = MediaQuery.padding.bottom + kFabSafeArea
/// ```
///
/// Uso já dentro de SafeArea:
/// ```dart
/// padding: EdgeInsets.only(bottom: kFabSafeArea),
/// ```
const double kFabSafeArea =
    kFabHeight + kFabShellBottomInset + kFabContentClearance; // 76.0

/// Altura mínima da barra de ações do modo desenho (sem medição).
///
/// Com medição integrada, o card cresce dinamicamente.
const double kDrawingBottomToolbarHeight = 64.0;

/// Recuo direito da barra de desenho para não cobrir o SmartButton global.
///
/// Composição: [kFabHeight] (56) + margem direita do shell (16) = 72.
const double kDrawingBottomToolbarRightInset = kFabHeight + 16.0;

/// Margem direita da coluna de ações do mapa (camadas / + / check-in).
const double kMapActionColumnRightInset = 16.0;

/// Tamanho dos botões circulares da coluna de ações do mapa.
const double kMapActionColumnButtonSize = 44.0;

/// Espaçamento vertical uniforme entre botões da coluna de ações do mapa.
const double kMapActionColumnSpacing = 12.0;

/// Inset inferior fixo da coluna de ações do mapa (âncora do check-in).
///
/// Composição: [kFabSafeArea] — alinhado ao SmartButton no AppShell
/// (`padding.bottom + 16` + 4dp de clearance).
///
/// REGRA-MAP-CHROME-1: **não** reagir a `mapSheetChromeInsetProvider` nem a
/// detent do bottom sheet — a coluna permanece estável enquanto o usuário
/// arrasta o sheet ou o app retoma do background.
const double kMapActionColumnBottomInset = kFabSafeArea;

/// Compensação vertical no modo desenho: mantém o botão de camadas na mesma
/// posição quando ações e check-in são ocultados.
const double kMapActionColumnDrawModeCompensation =
    (kMapActionColumnSpacing + kMapActionColumnButtonSize) * 2;
