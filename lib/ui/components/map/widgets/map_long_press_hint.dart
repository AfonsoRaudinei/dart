import 'package:flutter/material.dart';

import '../../../core/constants/layout_constants.dart';
import '../../../screens/map/utils/map_long_press_prefs.dart';

/// Hint progressivo: long press no mapa para ações rápidas.
class MapLongPressHint extends StatefulWidget {
  final bool visible;

  const MapLongPressHint({super.key, required this.visible});

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

  @override
  Widget build(BuildContext context) {
    if (!_keepInTree && !widget.visible) return const SizedBox.shrink();

    return Positioned(
      left: 24,
      right: 24,
      bottom:
          kFabSafeArea +
          MediaQuery.paddingOf(context).bottom +
          kMapLongPressHintBottomOffset,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fadeOpacity,
          child: FadeTransition(
            opacity: _pulseOpacity,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white.withValues(alpha: 0.92),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                        child: Text(
                          kMapLongPressHintMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }
}
