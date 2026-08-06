import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Toolbar horizontal flutuante para ações de desenho (cancelar, desfazer, confirmar).
///
/// Widget puro — sem acesso a providers. Callbacks injetados pelo host.
class DrawingBottomToolbar extends StatefulWidget {
  const DrawingBottomToolbar({
    super.key,
    required this.onConfirm,
    required this.onUndo,
    required this.onCancel,
    required this.canUndo,
    this.canConfirm = true,
  });

  final VoidCallback onConfirm;
  final VoidCallback onUndo;
  final VoidCallback onCancel;
  final bool canUndo;
  final bool canConfirm;

  @override
  State<DrawingBottomToolbar> createState() => _DrawingBottomToolbarState();
}

class _DrawingBottomToolbarState extends State<DrawingBottomToolbar>
    with SingleTickerProviderStateMixin {
  static const Color _iosRed = Color(0xFFFF3B30);
  static const Color _iosGreen = Color(0xFF34C759);

  late final AnimationController _entryController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ClipRRect(
        key: const Key('drawing_bottom_toolbar'),
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ToolbarAction(
                      icon: Icons.close_rounded,
                      label: 'Cancelar',
                      iconColor: _iosRed,
                      labelColor: Colors.white70,
                      iconSize: 22,
                      semanticsLabel: 'Cancelar desenho',
                      onTap: widget.onCancel,
                    ),
                  ),
                  const _ToolbarDivider(),
                  Expanded(
                    child: _ToolbarAction(
                      icon: Icons.undo_rounded,
                      label: 'Desfazer',
                      iconColor: Colors.white70,
                      labelColor: Colors.white70,
                      iconSize: 22,
                      semanticsLabel: 'Desfazer último ponto',
                      enabled: widget.canUndo,
                      onTap: widget.canUndo ? widget.onUndo : null,
                    ),
                  ),
                  const _ToolbarDivider(),
                  Expanded(
                    child: _ToolbarAction(
                      icon: Icons.check_rounded,
                      label: 'Confirmar',
                      iconColor: _iosGreen,
                      labelColor: _iosGreen,
                      iconSize: 22,
                      semanticsLabel: 'Confirmar desenho',
                      enabled: widget.canConfirm,
                      onTap: widget.canConfirm
                          ? () {
                              HapticFeedback.lightImpact();
                              widget.onConfirm();
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: Colors.white.withValues(alpha: 0.22),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.labelColor,
    required this.iconSize,
    required this.semanticsLabel,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final double iconSize;
  final String semanticsLabel;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.35;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      child: Opacity(
        opacity: opacity,
        child: Material(
          color: Colors.transparent,
            child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: iconSize),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: labelColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
