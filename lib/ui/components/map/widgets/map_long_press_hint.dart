import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../screens/map/utils/map_long_press_prefs.dart';

/// Hint progressivo: long press no mapa para registrar ocorrência.
class MapLongPressHint extends StatefulWidget {
  final bool visible;
  final VoidCallback? onAcknowledged;

  const MapLongPressHint({
    super.key,
    required this.visible,
    this.onAcknowledged,
  });

  @override
  State<MapLongPressHint> createState() => _MapLongPressHintState();
}

class _MapLongPressHintState extends State<MapLongPressHint>
    with TickerProviderStateMixin {
  static const Duration _fadeInDuration = Duration(milliseconds: 280);
  static const Duration _fadeOutDuration = Duration(milliseconds: 320);

  late final AnimationController _visibility;
  late final Animation<double> _fadeOpacity;

  late final AnimationController _pulse;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _scale;

  bool _keepInTree = false;

  @override
  void initState() {
    super.initState();
    _visibility = AnimationController(
      vsync: this,
      duration: _fadeInDuration,
      reverseDuration: _fadeOutDuration,
    );
    _fadeOpacity = CurvedAnimation(
      parent: _visibility,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulseOpacity = Tween<double>(
      begin: 0.72,
      end: 1,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _scale = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    if (widget.visible) {
      _keepInTree = true;
      _visibility.value = 1;
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MapLongPressHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      setState(() => _keepInTree = true);
      _visibility.forward(from: 0);
      _pulse.repeat(reverse: true);
    } else if (!widget.visible && oldWidget.visible) {
      _pulse.stop();
      _visibility.reverse().whenComplete(() {
        if (mounted && !widget.visible) {
          setState(() => _keepInTree = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _visibility.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _handleAcknowledgeTap() {
    HapticFeedback.lightImpact();
    widget.onAcknowledged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_keepInTree && !widget.visible) return const SizedBox.shrink();

    assert(
      !widget.visible || widget.onAcknowledged != null,
      'onAcknowledged is required when MapLongPressHint is visible',
    );

    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );

    return Positioned(
      left: 24,
      right: 24,
      bottom:
          kFabSafeArea +
          MediaQuery.paddingOf(context).bottom +
          kMapLongPressHintBottomOffset,
      child: FadeTransition(
        opacity: _fadeOpacity,
        child: FadeTransition(
          opacity: _pulseOpacity,
          child: ScaleTransition(
            scale: _scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IgnorePointer(
                      child: Icon(
                        SFIcons.warning,
                        color: Colors.white.withValues(alpha: 0.92),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: IgnorePointer(
                        child: Text(
                          kMapLongPressHintMessage,
                          style: bodyStyle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleAcknowledgeTap,
                          borderRadius: BorderRadius.circular(22),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Center(
                                  child: Text(
                                    kMapLongPressHintAcknowledgeLabel,
                                    style: bodyStyle?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
