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
/// Corresponde ao `bottom: 40` do Positioned no AppShell.
const double kFabBottomMargin = 40.0;

/// Margem de conforto acima do FAB para que o conteúdo não fique
/// visualmente colado ao botão.
const double kFabContentClearance = 4.0;

/// Altura total reservada para o SmartButton (FAB global).
///
/// Composição:
///   56dp  — altura do FAB (FloatingActionButton padrão)
///   40dp  — margem inferior do FAB (Positioned bottom: 40 no AppShell)
///    4dp  — clearance de conforto visual
/// ─────────
///  100dp  total fixo
///
/// Uso em qualquer ListView/ScrollView que chegue até o fundo:
/// ```dart
/// padding: EdgeInsets.only(bottom: kFabSafeArea),
/// ```
///
/// Para contextos com SafeArea, somar `MediaQuery.of(context).padding.bottom`
/// ou usar a extensão `context.fabSafeBottomPadding`.
const double kFabSafeArea = kFabHeight + kFabBottomMargin + kFabContentClearance; // 100.0
