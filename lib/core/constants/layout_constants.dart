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

/// Margem direita da coluna de ações do mapa (camadas / check-in).
const double kMapActionColumnRightInset = 16.0;

/// Tamanho visual e de toque dos botões da coluna de ações do mapa (Material 48dp).
const double kMapActionColumnButtonSize = 48.0;

/// Largura canônica dos cards de medição no mapa (área + detalhes empilhados).
const double kMapMeasurementCardWidth = 200.0;

/// Altura mínima de toque dos chips de unidade (ha/m²/alq, km/m).
const double kMapMeasurementUnitChipMinHeight = 34.0;

/// Área mínima de toque do toggle de detalhes de medição.
const double kMapMeasurementDetailsToggleMinSize = 36.0;

/// Offset acima do FAB para posicionar o hint de long press.
const double kMapLongPressHintBottomOffset = 24.0;

/// Gap entre camadas (superior) e check-in (inferior) — layout canônico 16dp.
///
/// Coluna atual (pós-remoção do botão +): layers → check-in → SmartButton.
const double kMapActionColumnSpacingAboveCheckIn = 16.0;

/// Folga extra entre o topo do SmartButton e a base da coluna (check-in).
/// 16dp no ritmo canônico da coluna — evita toque duplo FAB + check-in.
const double kMapActionColumnSpacingAboveFab = 16.0;

/// Inset inferior fixo da coluna de ações do mapa (âncora do check-in).
///
/// Composição: [kFabSafeArea] + [kMapActionColumnSpacingAboveFab]
/// → gap visual FAB↔check-in = kFabContentClearance + 16 = 20dp.
///
/// REGRA-MAP-CHROME-1: **não** reagir a `mapSheetChromeInsetProvider` nem a
/// detent do bottom sheet — a coluna permanece estável enquanto o usuário
/// arrasta o sheet ou o app retoma do background.
const double kMapActionColumnBottomInset =
    kFabSafeArea + kMapActionColumnSpacingAboveFab;

/// Compensação vertical no modo desenho: mantém o botão de camadas na mesma
/// posição quando check-in é ocultado.
///
/// Composição: gap 16 + botão 48 = 64dp.
const double kMapActionColumnDrawModeCompensation =
    kMapActionColumnSpacingAboveCheckIn + kMapActionColumnButtonSize;

/// Inset superior da fileira de toggles (basemap, pinos, localização).
///
/// Alinhado a `map_controls_overlay.dart` (`top: safeTop + 12`).
const double kMapTopControlsTopInset = 12.0;

/// Margem direita da fileira de toggles no topo do mapa.
const double kMapTopControlsRightInset = 12.0;

/// Espaçamento horizontal entre toggles da fileira superior.
const double kMapTopControlsButtonSpacing = 6.0;

/// Gap entre rótulo oculto e botão (basemap / pinos) na fileira superior.
const double kMapTopControlsToggleLabelButtonGap = 6.0;

/// Gap entre rótulo oculto e botão de localização na fileira superior.
const double kMapTopControlsLocationLabelButtonGap = 8.0;

/// Altura da fileira de toggles superiores (botões 48dp).
const double kMapTopControlsRowHeight = kMapActionColumnButtonSize;

/// Gap entre a base dos toggles topo e o chip de município.
const double kMapLocalityChipGapBelowTopControls = 10.0;

/// Rotação mínima (graus) para preservar ângulo do usuário ao sair do follow GPS.
const double kMapNorthCompassVisibleRotationDeg = 0.5;

/// Offset do chip de município abaixo do safe area (abaixo da fileira de toggles).
///
/// Composição: [kMapTopControlsTopInset] + [kMapTopControlsRowHeight] +
/// [kMapLocalityChipGapBelowTopControls] → 12 + 48 + 10 = 70dp.
const double kMapLocalityChipTopBelowSafeArea =
    kMapTopControlsTopInset +
    kMapTopControlsRowHeight +
    kMapLocalityChipGapBelowTopControls;

/// Largura reservada à direita para os três toggles topo (evita sobreposição do chip).
///
/// Inclui gaps fixos label→botão com rótulos ocultos (6 + 6 + 8).
///
/// Composição: [kMapTopControlsRightInset] + 2×(gap basemap/pinos + 48) +
/// (gap localização + 48) + 2×[kMapTopControlsButtonSpacing]
/// → 12 + 108 + 56 + 12 = 188dp.
const double kMapTopControlsReservedRightWidth =
    kMapTopControlsRightInset +
    (2 *
        (kMapTopControlsToggleLabelButtonGap + kMapActionColumnButtonSize)) +
    (kMapTopControlsLocationLabelButtonGap + kMapActionColumnButtonSize) +
    (2 * kMapTopControlsButtonSpacing);

/// Fileira superior com indicador de feature selecionada (4.º botão circular).
const double kMapTopControlsSelectedFeatureChromeWidth =
    kMapTopControlsButtonSpacing + kMapActionColumnButtonSize;

/// Card de contexto do mapa (produtor e consultor) no canto inferior esquerdo.
///
/// 36dp livra o botão de atribuição do flutter_map.
const double kMapContextCardLeftInset = 12.0;

/// Folga entre a base do card de contexto e a borda útil (acima da safe area).
const double kMapContextCardBottomInset = 36.0;

/// Folga entre o card de contexto e a coluna de ações (lápis / check-in).
const double kMapContextCardColumnGap = 12.0;

/// Folga entre o card de contexto e a toolbar de desenho, quando ela está visível.
const double kMapContextCardToolbarGap = 8.0;

/// Largura máxima do card de contexto: a tela menos a margem esquerda e a coluna direita.
double mapContextCardMaxWidth(double screenWidth) {
  return screenWidth -
      kMapContextCardLeftInset -
      kMapActionColumnRightInset -
      kMapActionColumnButtonSize -
      kMapContextCardColumnGap;
}
