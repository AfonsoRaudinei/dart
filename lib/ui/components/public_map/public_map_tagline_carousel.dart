import 'dart:async';

import 'package:flutter/material.dart';

/// Par de textos de um slide da vitrine pública.
class PublicMapTaglineSlide {
  const PublicMapTaglineSlide({
    required this.headline,
    required this.support,
  });

  final String headline;
  final String support;
}

/// Carrossel fade de taglines acima do CTA da vitrine `/public-map`.
///
/// Sem gesto e sem dots. [IgnorePointer] deixa pan/zoom do mapa passar.
class PublicMapTaglineCarousel extends StatefulWidget {
  const PublicMapTaglineCarousel({super.key});

  static const Duration interval = Duration(milliseconds: 4500);
  static const Duration fadeDuration = Duration(milliseconds: 400);

  static const List<PublicMapTaglineSlide> slides = [
    PublicMapTaglineSlide(
      headline: 'Simples. Poderoso. Teu.',
      support: 'A experiência e a sabedoria falam alto na lavoura.',
    ),
    PublicMapTaglineSlide(
      headline: 'Tradição e tecnologia no mesmo solo.',
      support:
          'Reúna a prática de campo e decisão técnica com mais clareza.',
    ),
    PublicMapTaglineSlide(
      headline: 'Confiável para o dia a dia da propriedade.',
      support: 'Acompanhe dados importantes sem perder o ritmo da operação.',
    ),
  ];

  @override
  State<PublicMapTaglineCarousel> createState() =>
      _PublicMapTaglineCarouselState();
}

class _PublicMapTaglineCarouselState extends State<PublicMapTaglineCarousel> {
  static const _textShadow = Shadow(
    color: Color(0x66000000),
    blurRadius: 8,
    offset: Offset(0, 1),
  );

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
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedSwitcher(
          duration: PublicMapTaglineCarousel.fadeDuration,
          child: Column(
            key: ValueKey<int>(_index),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slide.headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.2,
                  letterSpacing: -0.2,
                  shadows: [_textShadow],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                slide.support,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                  shadows: const [_textShadow],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
