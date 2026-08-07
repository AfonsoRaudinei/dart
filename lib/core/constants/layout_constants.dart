/// ════════════════════════════════════════════════════════════════════
/// LAYOUT CONSTANTS — SOLOFORTE
/// ════════════════════════════════════════════════════════════════════
///
/// Constantes de layout compartilhadas entre todos os módulos.
/// Qualquer valor de posicionamento ou padding que precisa ser
/// consistente no sistema inteiro deve ser definido aqui.
///
/// REGRA: Nunca hard-code valores de padding/margin que dependem
/// do SmartButton. Use sempre [kFabSafeArea].
/// ════════════════════════════════════════════════════════════════════
library;

/// Altura padrão do FloatingActionButton (Material Design).
const double kFabHeight = 56.0;

/// Margem inferior do SmartButton até a borda da safe area.
///
/// Fonte da verdade: [AppShell] Positioned
/// `bottom: MediaQuery.padding.bottom + 16`.
/// Este valor é só a margem acima da safe area (16dp), não inclui
/// `padding.bottom` — somar via [FabSafeAreaExtension.fabSafeBottomPadding]
/// ou `MediaQuery.padding.bottom` quando o layout não estiver em SafeArea.
const double kFabBottomMargin = 16.0;

/// Margem de conforto acima do FAB para que o conteúdo não fique
/// visualmente colado ao botão.
const double kFabContentClearance = 4.0;

/// Altura total reservada para o SmartButton (FAB global),
/// **sem** a safe area do dispositivo.
///
/// Composição:
///   56dp  — altura do FAB (FloatingActionButton padrão)
///   16dp  — margem inferior do FAB (AppShell: padding.bottom + 16)
///    4dp  — clearance de conforto visual
/// ─────────
///   76dp  total fixo
///
/// Uso em qualquer ListView/ScrollView que chegue até o fundo
/// (quando o body já respeita SafeArea inferior):
/// ```dart
/// padding: EdgeInsets.only(bottom: kFabSafeArea),
/// ```
///
/// Fora de SafeArea, somar `MediaQuery.of(context).padding.bottom`
/// ou usar a extensão `context.fabSafeBottomPadding`.
const double kFabSafeArea = kFabHeight + kFabBottomMargin + kFabContentClearance; // 76.0

/// Altura mínima da barra de ações do modo desenho (sem medição).
///
/// Com medição integrada, o card cresce dinamicamente.
const double kDrawingBottomToolbarHeight = 64.0;

/// Recuo direito da barra de desenho para não cobrir o SmartButton global.
///
/// Composição: [kFabHeight] (56) + margem direita do shell (16) = 72.
const double kDrawingBottomToolbarRightInset = kFabHeight + 16.0;
