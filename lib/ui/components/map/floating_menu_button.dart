import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';

/// Botão de menu flutuante isolado — Canto inferior direito
/// Verde SoloForte (#22C55E), circular, com ícone de menu
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
    const soloForteGreen = Color(0xFF22C55E);

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 22,
      right: 20,
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
              color: soloForteGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: soloForteGreen.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(SFIcons.menu, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
