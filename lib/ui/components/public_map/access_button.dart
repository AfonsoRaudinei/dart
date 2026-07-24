import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';

/// Card flutuante de acesso ao SoloForte no mapa público.
///
/// Vidro fosco (glass) com entrada suave, microinteração de toque e
/// retração discreta enquanto o mapa se move.
class AccessSoloForteButton extends StatefulWidget {
  const AccessSoloForteButton({
    super.key,
    this.isMapMoving = false,
  });

  /// Quando `true`, o card recolhe ~8% e desce alguns pixels.
  final bool isMapMoving;

  @override
  State<AccessSoloForteButton> createState() => _AccessSoloForteButtonState();
}

class _AccessSoloForteButtonState extends State<AccessSoloForteButton>
    with SingleTickerProviderStateMixin {
  static const Color _samsungGreen = Color(0xFF34C759);
  static const Color _titleColor = Color(0xFF1D1D1F);
  static const Color _subtitleColor = Color(0xFF6D6D72);
  static const double _radius = 30;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<double> _entranceLift;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceFade = curved;
    // Sobe 20px (de +20 → 0) com easeOutCubic — sem deslize rápido.
    _entranceLift = Tween<double>(begin: 20, end: 0).animate(curved);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    context.go(AppRoutes.login);
  }

  List<BoxShadow> get _shadow {
    if (_pressed) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
    }
    if (widget.isMapMoving) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ];
  }

  double get _interactiveScale {
    if (_pressed) return 0.98;
    if (widget.isMapMoving) return 0.92;
    return 1.0;
  }

  Offset get _interactiveOffset {
    if (widget.isMapMoving) return const Offset(0, 6);
    return Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Acessar SoloForte - Fazer login ou criar conta',
      button: true,
      child: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, child) {
          return Opacity(
            opacity: _entranceFade.value,
            child: Transform.translate(
              offset: Offset(0, _entranceLift.value),
              child: child,
            ),
          );
        },
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          offset: Offset(
            0,
            _interactiveOffset.dy / 80, // ~6px quando o mapa move
          ),
          child: AnimatedScale(
            scale: _interactiveScale,
            duration: Duration(milliseconds: _pressed ? 120 : 250),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: Duration(milliseconds: _pressed ? 120 : 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: _shadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onTap,
                      onTapDown: (_) => _setPressed(true),
                      onTapUp: (_) => _setPressed(false),
                      onTapCancel: () => _setPressed(false),
                      borderRadius: BorderRadius.circular(_radius),
                      splashColor: _samsungGreen.withValues(alpha: 0.08),
                      highlightColor: Colors.white.withValues(alpha: 0.08),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(_radius),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Barra lateral — detalhe 3px Samsung green
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Container(
                                  width: 3,
                                  margin: const EdgeInsets.only(left: 14),
                                  decoration: BoxDecoration(
                                    color: _samsungGreen,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    18,
                                    8,
                                    18,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RichText(
                                        text: const TextSpan(
                                          // iOS resolve para SF Pro Display; Android usa a família do tema.
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600,
                                            height: 1.15,
                                            letterSpacing: -0.4,
                                            color: _titleColor,
                                          ),
                                          children: [
                                            TextSpan(text: 'Acessar '),
                                            TextSpan(
                                              text: 'SoloForte',
                                              style: TextStyle(
                                                color: Color(0xFF1B7A3A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Tecnologia com raiz.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          height: 1.25,
                                          letterSpacing: -0.2,
                                          color: _subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Logo transparente — só o símbolo
                              Padding(
                                padding: const EdgeInsets.only(right: 18),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/soloforte_logo.png',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
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
          ),
        ),
      ),
    );
  }
}
