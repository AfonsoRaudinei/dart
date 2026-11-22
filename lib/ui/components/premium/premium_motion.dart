import 'package:flutter/material.dart';

/// Movimento sutil e consistente (150–250 ms). Tudo aqui respeita a opção de
/// acessibilidade "reduzir movimento" (`MediaQuery.disableAnimations`).
const Duration kPremiumPressDuration = Duration(milliseconds: 120);
const Duration kPremiumCountDuration = Duration(milliseconds: 450);

/// Cartão que "afunda" levemente ao toque (escala 0.97), como no iOS.
///
/// Usa [Listener], então não interfere nos gestos do filho (toque, deslizar).
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && !reduce ? widget.pressedScale : 1,
        duration: reduce ? Duration.zero : kPremiumPressDuration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Número que sobe de 0 até [value] ao aparecer (e anima mudanças).
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCount({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text('$value', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: kPremiumCountDuration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}
