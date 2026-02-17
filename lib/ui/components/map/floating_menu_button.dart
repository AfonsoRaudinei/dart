import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';
import '../../theme/soloforte_theme.dart';

/// Botão de menu flutuante isolado — Canto inferior direito
/// Verde SoloForte (Primary), circular, com ícone de menu
/// Refatorado para Design System v2 (Map-First Premium)
class FloatingMenuButton extends StatefulWidget {
  final VoidCallback onTap;

  const FloatingMenuButton({super.key, required this.onTap});

  @override
  State<FloatingMenuButton> createState() => _FloatingMenuButtonState();
}

class _FloatingMenuButtonState extends State<FloatingMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usando tokens oficiais
    final primaryColor = SoloForteColors.primary;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24, // 24px do bottom safe
      right: 16, // Contrato: 16px da borda lateral
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: SoloShadows.shadowButton, // Sombra padrão
            ),
            child: const Icon(SFIcons.menu, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
