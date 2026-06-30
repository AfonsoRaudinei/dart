import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../theme/premium/design_tokens.dart';
import '../../premium/premium_glass_panel.dart';
import 'publication_actions_bottom_sheet.dart';

enum MapActionFabMenuDirection { up, left }

/// Menu mestre visual para acoes de conteudo no mapa.
///
/// Fase 1: componente isolado, sem provider, sem model e sem regra de negocio.
/// O parent injeta os callbacks e decide o que cada acao faz.
class MapActionFabMenu extends StatefulWidget {
  final VoidCallback onResultado;
  final VoidCallback onAntesDepois;
  final VoidCallback onAvaliacao;
  final VoidCallback onOcorrencia;
  final VoidCallback onFotoRapida;
  final VoidCallback onInversaoVegetal;
  final bool isEnabled;
  final bool isActive;
  final Color activeColor;
  final EdgeInsets padding;
  final double right;
  final double? top;
  final double? bottom;
  final MapActionFabMenuDirection direction;
  final bool useLegacyExpandedMenu;

  const MapActionFabMenu({
    super.key,
    required this.onResultado,
    required this.onAntesDepois,
    required this.onAvaliacao,
    required this.onOcorrencia,
    required this.onFotoRapida,
    required this.onInversaoVegetal,
    this.isEnabled = true,
    this.isActive = false,
    required this.activeColor,
    this.padding = const EdgeInsets.only(right: 16, bottom: 24),
    this.right = 0,
    this.top,
    this.bottom = 0,
    this.direction = MapActionFabMenuDirection.up,
    this.useLegacyExpandedMenu = false,
  });

  @override
  State<MapActionFabMenu> createState() => _MapActionFabMenuState();
}

class _MapActionFabMenuState extends State<MapActionFabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(BuildContext context) {
    if (!widget.isEnabled) return;
    HapticFeedback.selectionClick();
    PublicationActionsBottomSheet.show(
      context: context,
      onResultado: widget.onResultado,
      onAntesDepois: widget.onAntesDepois,
      onAvaliacao: widget.onAvaliacao,
      onOcorrencia: widget.onOcorrencia,
      onFotoRapida: widget.onFotoRapida,
      onInversaoVegetal: widget.onInversaoVegetal,
    );
  }

  void _toggleLegacy() {
    if (!widget.isEnabled) return;
    HapticFeedback.selectionClick();
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _controller.reverse();
  }

  void _runAction(VoidCallback action) {
    HapticFeedback.lightImpact();
    _close();
    action();
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MenuActionButton(
          icon: SFIcons.barChart,
          label: 'Resultado',
          color: PremiumTokens.brandGreen,
          onTap: () => _runAction(widget.onResultado),
        ),
        const SizedBox(height: 10),
        _MenuActionButton(
          icon: SFIcons.compareArrows,
          label: 'Antes/Depois',
          color: const Color(0xFFF59E0B),
          onTap: () => _runAction(widget.onAntesDepois),
        ),
        const SizedBox(height: 10),
        _MenuActionButton(
          icon: SFIcons.science,
          label: 'Avaliação',
          color: const Color(0xFF3B82F6),
          onTap: () => _runAction(widget.onAvaliacao),
        ),
        const SizedBox(height: 10),
        _MenuActionButton(
          icon: SFIcons.warning,
          label: 'Ocorrência',
          color: PremiumTokens.alertWarning,
          onTap: () => _runAction(widget.onOcorrencia),
        ),
        const SizedBox(height: 10),
        _MenuActionButton(
          icon: SFIcons.leaf,
          label: 'Inversão vegetal',
          color: PremiumTokens.brandGreen,
          onTap: () => _runAction(widget.onInversaoVegetal),
        ),
      ],
    );
  }

  Widget _buildMenuBody() {
    if (widget.useLegacyExpandedMenu) {
      return _buildLegacyMenuBody();
    }

    return _MasterFab(
      isOpen: false,
      isActive: widget.isActive,
      activeColor: widget.activeColor,
      onTap: () => _toggle(context),
    );
  }

  Widget _buildLegacyMenuBody() {
    final actions = IgnorePointer(
      ignoring: !_isOpen,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          alignment: widget.direction == MapActionFabMenuDirection.left
              ? Alignment.centerRight
              : Alignment.bottomRight,
          child: _buildActions(),
        ),
      ),
    );

    if (widget.direction == MapActionFabMenuDirection.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          actions,
          const SizedBox(width: 12),
          _MasterFab(
            isOpen: _isOpen,
            isActive: widget.isActive,
            activeColor: widget.activeColor,
            onTap: _toggleLegacy,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        actions,
        const SizedBox(height: 12),
        _MasterFab(
          isOpen: _isOpen,
          isActive: widget.isActive,
          activeColor: widget.activeColor,
          onTap: _toggleLegacy,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
        Positioned(
          right: widget.right,
          top: widget.top,
          bottom: widget.top == null ? widget.bottom : null,
          child: SafeArea(
            top: false,
            minimum: widget.padding,
            child: _buildMenuBody(),
          ),
        ),
      ],
    );
  }
}

class _MasterFab extends StatelessWidget {
  final bool isOpen;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _MasterFab({
    required this.isOpen,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isOpen ? 'Fechar' : 'Ações',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Icon(
              isOpen ? SFIcons.close : SFIcons.add,
              color: isOpen || isActive ? activeColor : Colors.grey.shade600,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            PremiumGlassPanel(
              borderRadius: BorderRadius.circular(99),
              isDark: true,
              padding: EdgeInsets.zero,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18),
                  border: Border.all(
                    color: color.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
