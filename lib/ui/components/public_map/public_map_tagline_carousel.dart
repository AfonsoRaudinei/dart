import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/components/premium/premium_glass_panel.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

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
/// Sem gesto. [IgnorePointer] deixa pan/zoom do mapa passar.
class PublicMapTaglineCarousel extends StatefulWidget {
  const PublicMapTaglineCarousel({super.key});

  static const Duration interval = Duration(milliseconds: 4500);
  static const Duration fadeDuration = Duration(milliseconds: 400);

  /// Vidro + dots — altura fixa para evitar salto entre slides.
  static const double blockHeight = 132;

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
        child: SizedBox(
          height: PublicMapTaglineCarousel.blockHeight,
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: PublicMapTaglineCarousel.fadeDuration,
                  child: PremiumGlassPanel(
                    key: ValueKey<int>(_index),
                    isDark: true,
                    borderRadius: BorderRadius.circular(
                      PremiumTokens.borderRadiusMd,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          slide.headline,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            height: 1.2,
                            letterSpacing: -0.3,
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
                            fontSize: 13,
                            height: 1.25,
                            letterSpacing: -0.3,
                            shadows: const [_textShadow],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _PageDots(
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

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(
                alpha: isActive ? 0.9 : 0.35,
              ),
            ),
          ),
        );
      }),
    );
  }
}
