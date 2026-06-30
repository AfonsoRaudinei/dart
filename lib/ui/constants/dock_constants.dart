/*
════════════════════════════════════════════════════════════════════
DOCK CONSTANTS — FONTE DA VERDADE ESTRUTURAL
════════════════════════════════════════════════════════════════════

Constante global da zona inferior protegida (Dock).
Valor fixo único, nunca recalculado, nunca redefinido por tela.

Representa a altura útil do dock (botão 44px + margem 6px = 50px).
SafeArea é tratada separadamente pelo AppShell.

REGRA ABSOLUTA:
- Qualquer componente que posicione algo na base da tela DEVE
  usar kDockHeight para reservar espaço.
- BottomSheets: bottom = MediaQuery.padding.bottom + kDockHeight
- ScrollViews: padding bottom = kDockHeight
════════════════════════════════════════════════════════════════════
*/

/// Altura fixa da zona útil do dock.
///
/// Valor calculado: botão 44px + margem estrutural 6px = 50px.
/// SafeArea bottom inset é adicionado separadamente pelo shell.
const double kDockHeight = 50.0;
