// Removed dart:ui
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../modules/map/design/sf_icons.dart';
// deleted
import '../../theme/premium/design_tokens.dart';
import '../premium/premium_glass_panel.dart';

/// Dock Glass — barra de ícones glass na zona inferior do /map.
///
/// Layout:
/// ┌──────────────────────────────┐
/// │  [✏] [🗂] [⚠] [📣] [✅]    │
/// │  ← glass pill 50px →        │
/// └──────────────────────────────┘
///
/// CONTRATO:
/// - Renderizado em Positioned(bottom: 0, height: dockSafeHeight)
/// - SafeArea(top: false, bottom: true) preserva insets do sistema
/// - Espaço útil: kDockHeight (50px)
/// - FloatingMenuButton está no PrivateAppShell (não aqui)
/// - BottomSheets permanecem em bottom: dockSafeHeight (blindagem intacta)
/// - Blur somente no container glass, não na zona inteira
class MapDockGlass extends StatelessWidget {
  // ── Estado ativo dos ícones ──────────────────────────────────────
  final bool isDrawMode;
  final bool isOccurrenceMode;
  final bool isLayersOpen;
  final bool isPublicationsOpen;
  final bool isCheckInOpen;

  /// Quando um sheet está aberto, o dock recua sutilmente.
  final bool isSheetOpen;

  // ── Callbacks ────────────────────────────────────────────────────
  final VoidCallback onDraw;
  final VoidCallback onLayers;
  final VoidCallback onOccurrences;
  final VoidCallback onPublications;
  final VoidCallback onCheckIn;

  const MapDockGlass({
    super.key,
    required this.isDrawMode,
    required this.isOccurrenceMode,
    required this.isLayersOpen,
    required this.isPublicationsOpen,
    required this.isCheckInOpen,
    required this.isSheetOpen,
    required this.onDraw,
    required this.onLayers,
    required this.onOccurrences,
    required this.onPublications,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isSheetOpen ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: isSheetOpen ? 0.96 : 1.0,
        alignment: Alignment.bottomCenter,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: SafeArea(
          top: false,
          bottom: true,
          child: SizedBox(
            // Espaço útil: kDockHeight = 50px
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _GlassIconGroup(
                  isDrawMode: isDrawMode,
                  isOccurrenceMode: isOccurrenceMode,
                  isLayersOpen: isLayersOpen,
                  isPublicationsOpen: isPublicationsOpen,
                  isCheckInOpen: isCheckInOpen,
                  onDraw: onDraw,
                  onLayers: onLayers,
                  onOccurrences: onOccurrences,
                  onPublications: onPublications,
                  onCheckIn: onCheckIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Icon Group — pill com blur somente neste container
// ─────────────────────────────────────────────────────────────────────────────
class _GlassIconGroup extends StatelessWidget {
  final bool isDrawMode;
  final bool isOccurrenceMode;
  final bool isLayersOpen;
  final bool isPublicationsOpen;
  final bool isCheckInOpen;
  final VoidCallback onDraw;
  final VoidCallback onLayers;
  final VoidCallback onOccurrences;
  final VoidCallback onPublications;
  final VoidCallback onCheckIn;

  const _GlassIconGroup({
    required this.isDrawMode,
    required this.isOccurrenceMode,
    required this.isLayersOpen,
    required this.isPublicationsOpen,
    required this.isCheckInOpen,
    required this.onDraw,
    required this.onLayers,
    required this.onOccurrences,
    required this.onPublications,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassPanel(
      borderRadius: BorderRadius.circular(99.0), // Pilula Redonda Circular iOS
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DockIcon(icon: SFIcons.edit, isActive: isDrawMode, onTap: onDraw),
            const SizedBox(width: 14),
            _DockIcon(
              icon: SFIcons.layers,
              isActive: isLayersOpen,
              onTap: onLayers,
            ),
            const SizedBox(width: 14),
            _DockIcon(
              icon: SFIcons.warning,
              isActive: isOccurrenceMode,
              onTap: onOccurrences,
            ),
            const SizedBox(width: 14),
            _DockIcon(
              icon: SFIcons.articleOutlined,
              isActive: isPublicationsOpen,
              onTap: onPublications,
            ),
            const SizedBox(width: 14),
            _DockIcon(
              icon: SFIcons.checkCircle,
              isActive: isCheckInOpen,
              onTap: onCheckIn,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dock Icon — ícone individual com área de toque expandida
// ─────────────────────────────────────────────────────────────────────────────
class _DockIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DockIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 26,
        height: 50,
        child: Center(
          child: Icon(
            icon,
            size: 26,
            color: isActive
                ? PremiumTokens.brandGreen
                : Colors.black.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
