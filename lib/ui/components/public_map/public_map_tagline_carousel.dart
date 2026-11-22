import 'dart:async';

import 'package:flutter/material.dart';

/// Par de textos de um slide da vitrine pública.
class PublicMapTaglineSlide {
  const PublicMapTaglineSlide({required this.headline, required this.support});

  final String headline;
  final String support;
}

/// Frases da vitrine `/public-map`, em voz de colega de campo (sem painel):
/// o texto aparece direto sobre o degradê, com entrada suave em duas camadas
/// (título e depois apoio), sem gesto. [IgnorePointer] deixa pan/zoom do mapa
/// passar. Respeita "reduzir movimento".
class PublicMapTaglineCarousel extends StatefulWidget {
  const PublicMapTaglineCarousel({super.key});

  static const Duration interval = Duration(milliseconds: 5200);
  static const Duration fadeDuration = Duration(milliseconds: 500);

  /// Texto + indicador — altura fixa para evitar salto entre slides.
  static const double blockHeight = 150;

  static const List<PublicMapTaglineSlide> slides = [
    PublicMapTaglineSlide(
      headline: 'Seu campo, do seu jeito.',
      support: 'Registre visitas, talhões e ocorrências no mesmo lugar.',
    ),
    PublicMapTaglineSlide(
      headline: 'Feito por quem entende de lavoura.',
      support: 'Menos papel, mais tempo com o produtor.',
    ),
    PublicMapTaglineSlide(
      headline: 'Seu trabalho merece ser visto.',
      support: 'Transforme o que você vê no campo em relatórios claros.',
    ),
  ];

  @override
  State<PublicMapTaglineCarousel> createState() =>
      _PublicMapTaglineCarouselState();
}

class _PublicMapTaglineCarouselState extends State<PublicMapTaglineCarousel> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(PublicMapTaglineCarousel.interval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % PublicMapTaglineCarousel.slides.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = PublicMapTaglineCarousel.slides[_index];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: PublicMapTaglineCarousel.blockHeight,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : PublicMapTaglineCarousel.fadeDuration,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, ?current],
                  ),
                  child: _SlideText(
                    key: ValueKey<int>(_index),
                    slide: slide,
                    animate: !reduceMotion,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ProgressBars(
                count: PublicMapTaglineCarousel.slides.length,
                activeIndex: _index,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Título e apoio com entrada escalonada: sobem 14 px e aparecem, o apoio
/// começa um pouco depois — leitura natural, sem "pisca" de painel.
class _SlideText extends StatefulWidget {
  const _SlideText({super.key, required this.slide, required this.animate});

  final PublicMapTaglineSlide slide;
  final bool animate;

  @override
  State<_SlideText> createState() => _SlideTextState();
}

class _SlideTextState extends State<_SlideText>
    with SingleTickerProviderStateMixin {
  static const _shadow = Shadow(
    color: Color(0x73000000),
    blurRadius: 10,
    offset: Offset(0, 1),
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _reveal(Widget child, {required double from, required double to}) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.28),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _reveal(
          Text(
            widget.slide.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 27,
              height: 1.12,
              letterSpacing: -0.6,
              shadows: [_shadow],
            ),
          ),
          from: 0,
          to: 0.7,
        ),
        const SizedBox(height: 8),
        _reveal(
          Text(
            widget.slide.support,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.3,
              shadows: const [_shadow],
            ),
          ),
          from: 0.25,
          to: 1,
        ),
      ],
    );
  }
}

/// Indicador em barras finas (o ativo se alonga), no lugar das bolinhas.
class _ProgressBars extends StatelessWidget {
  const _ProgressBars({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: isActive ? 28 : 10,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.4),
            ),
          ),
        );
      }),
    );
  }
}
