import 'package:flutter/material.dart';

/// Hint progressivo: long press no mapa para ações rápidas.
class MapLongPressHint extends StatefulWidget {
  final bool visible;

  const MapLongPressHint({super.key, required this.visible});

  @override
  State<MapLongPressHint> createState() => _MapLongPressHintState();
}

class _MapLongPressHintState extends State<MapLongPressHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _opacity = Tween<double>(
      begin: 0.72,
      end: 1,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _scale = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    if (widget.visible) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MapLongPressHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _pulse.repeat(reverse: true);
    } else if (!widget.visible && oldWidget.visible) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Positioned(
      left: 24,
      right: 24,
      bottom: MediaQuery.of(context).size.height * 0.28,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
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
                          'Pressione o mapa para registrar uma ação',
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
    );
  }
}
