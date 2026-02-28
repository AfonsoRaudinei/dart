/*
════════════════════════════════════════════════════════════════════
PRIVATE APP SHELL — ESTRUTURA UNIFICADA PARA TELAS AUTENTICADAS
════════════════════════════════════════════════════════════════════

Shell estrutural base para TODAS as telas privadas do app.
Centraliza o dock zone e o FloatingMenuButton.

RESPONSABILIDADES EXCLUSIVAS:
 ✅ Stack raiz
 ✅ Reservar espaço fixo do Dock (kDockHeight)
 ✅ Renderizar FloatingMenuButton em posição fixa
 ✅ SafeArea inferior (apenas no dock zone)

NÃO CONTÉM:
 ❌ Lógica de negócio
 ❌ Scaffold
 ❌ MediaQuery
 ❌ Provider/Riverpod
 ❌ Variações por módulo

HIERARQUIA:
 PrivateAppShell (Stack)
 ├── Positioned.fill → child (full-bleed)
 └── Positioned(bottom: 0, right: 16) → SafeArea → FloatingMenuButton

CONTRATO:
 - Child ocupa tela inteira (full-bleed)
 - Cada tela gerencia seu próprio padding inferior via kDockHeight
 - FloatingMenuButton fixo no canto inferior direito
 - SafeArea aplicada apenas ao dock zone
 - onMenuTap: callback puro, sem acoplamento a provider

POSICIONAMENTO DO BOTÃO:
 - SafeArea(bottom: true) eleva o botão acima dos system insets
 - SizedBox(height: kDockHeight = 50px) centraliza o botão (44px)
 - Sobra: 50 - 44 = 6px → 3px acima / 3px abaixo
════════════════════════════════════════════════════════════════════
*/

import 'package:flutter/material.dart';
import '../constants/dock_constants.dart';
import 'map/floating_menu_button.dart';

class PrivateAppShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onMenuTap;

  const PrivateAppShell({
    super.key,
    required this.child,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Layer 1: Conteúdo da tela (full-bleed) ───────────────────
        // Cada tela gerencia seu próprio padding inferior usando
        // a constante global kDockHeight.
        Positioned.fill(child: child),

        // ── Layer 2: FloatingMenuButton — posição fixa ───────────────
        // bottom: 0 + SafeArea = botão acima dos system insets
        // right: 16 = margem lateral padrão
        // SizedBox(kDockHeight) = centra o botão 44px na zona de 50px
        Positioned(
          bottom: 0,
          right: 16,
          child: SafeArea(
            top: false,
            bottom: true,
            child: SizedBox(
              height: kDockHeight,
              child: Center(child: FloatingMenuButton(onTap: onMenuTap)),
            ),
          ),
        ),
      ],
    );
  }
}
