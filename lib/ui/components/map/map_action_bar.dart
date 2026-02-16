import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';

/// Tab Bar estrutural de domínios - Somente ícones (padrão iOS)
/// 4 tabs: Mapa, Operações, Gestão, Perfil
class MapTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabTap;

  const MapTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TabButton(
              icon: SFIcons.map,
              isSelected: selectedIndex == 0,
              onTap: () => onTabTap(0),
            ),
            _TabButton(
              icon: SFIcons.work,
              isSelected: selectedIndex == 1,
              onTap: () => onTabTap(1),
            ),
            _TabButton(
              icon: SFIcons.businessCenter,
              isSelected: selectedIndex == 2,
              onTap: () => onTabTap(2),
            ),
            _TabButton(
              icon: SFIcons.person,
              isSelected: selectedIndex == 3,
              onTap: () => onTabTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_TabButton oldWidget) {
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
    const activeColor = Color(0xFF22C55E); // Verde SoloForte
    final inactiveColor = Colors.black.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: widget.isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              widget.icon,
              size: 26,
              color: widget.isSelected ? Colors.white : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}
