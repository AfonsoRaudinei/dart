import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';

/// Bottom Nav flutuante em cápsula — Estilo iOS clean
/// 4 ações do mapa: Mapa, Publicações, Ocorrências, Check-in
class FloatingDockWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabTap;

  const FloatingDockWidget({
    super.key,
    required this.selectedIndex,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: IntrinsicWidth(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavItem(
                      icon: SFIcons.mapOutlined,
                      activeIcon: SFIcons.map,
                      isSelected: selectedIndex == 0,
                      onTap: () => onTabTap(0),
                    ),
                    const SizedBox(width: 20),
                    _NavItem(
                      icon: SFIcons.articleOutlined,
                      activeIcon: SFIcons.article,
                      isSelected: selectedIndex == 1,
                      onTap: () => onTabTap(1),
                    ),
                    const SizedBox(width: 20),
                    _NavItem(
                      icon: SFIcons.warningOutlined,
                      activeIcon: SFIcons.warning,
                      isSelected: selectedIndex == 2,
                      onTap: () => onTabTap(2),
                    ),
                    const SizedBox(width: 20),
                    _NavItem(
                      icon: SFIcons.checkCircleOutlined,
                      activeIcon: SFIcons.checkCircle,
                      isSelected: selectedIndex == 3,
                      onTap: () => onTabTap(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item individual da nav flutuante
class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  static const _soloForteGreen = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
    if (widget.isSelected) {
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleController.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _scaleController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.isSelected ? _soloForteGreen : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isSelected ? widget.activeIcon : widget.icon,
            size: 24,
            color: widget.isSelected
                ? Colors.white
                : Colors.black.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
