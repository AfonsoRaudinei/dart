import 'package:flutter/material.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../domain/marketing_case_media.dart';
import 'marketing_media_image.dart';

/// Pin rico para o mapa — foto sem crop, produto e ROI por tier.
///
/// ADR-011: hierarquia visual Ouro > Prata > Bronze.
/// Anchor: bottomCenter (ponteiro aponta para a coordenada no mapa).
/// Retrato compacto + [BoxFit.contain] (foto de celular inteira).
class MarketingCaseMarker extends StatelessWidget {
  final MarketingCase marketingCase;
  final VoidCallback onTap;

  const MarketingCaseMarker({
    super.key,
    required this.marketingCase,
    required this.onTap,
  });

  // ─── Dimensões por tier (retrato: mais alto que largo) ────────
  static double pinWidth(PlanoMarketing tier) => switch (tier) {
    PlanoMarketing.ouro => 96,
    PlanoMarketing.prata => 84,
    PlanoMarketing.bronze => 72,
  };

  static double pinHeight(PlanoMarketing tier) => switch (tier) {
    PlanoMarketing.ouro => 132,
    PlanoMarketing.prata => 116,
    PlanoMarketing.bronze => 100,
  };

  static double minZoomForTier(PlanoMarketing tier) => switch (tier) {
    PlanoMarketing.ouro => 10.0,
    PlanoMarketing.prata => 12.0,
    PlanoMarketing.bronze => 14.0,
  };

  static bool isVisibleAtZoom(PlanoMarketing tier, double zoom) {
    return zoom >= minZoomForTier(tier);
  }

  static double _borderWidth(PlanoMarketing tier) => switch (tier) {
    PlanoMarketing.ouro => 3.0,
    PlanoMarketing.prata => 2.5,
    PlanoMarketing.bronze => 2.0,
  };

  static Color _borderColor(PlanoMarketing tier) => switch (tier) {
    PlanoMarketing.ouro => const Color(0xFFFFD700),
    PlanoMarketing.prata => const Color(0xFFC0C0C0),
    PlanoMarketing.bronze => const Color(0xFFCD7F32),
  };

  static Color _placeholderColor(PlanoMarketing tier) => switch (tier) {
    PlanoMarketing.ouro => const Color(0xFF2C2400),
    PlanoMarketing.prata => const Color(0xFF252525),
    PlanoMarketing.bronze => const Color(0xFF1E1200),
  };

  String? _resultText() {
    final resultadoRoi = marketingCase.computeRoi();
    if (resultadoRoi != null) {
      return 'ROI ${_moneyCompact(resultadoRoi.roiLiquidoRsHa)}/ha';
    }

    final roi = marketingCase.roi;
    if (roi != null && roi.roiCalculado > 0) {
      return 'ROI ${roi.roiCalculado.toStringAsFixed(0)}%';
    }

    if (marketingCase.parametros.isNotEmpty) {
      return '${_signed(marketingCase.mediaGanhoPercent)}%';
    }

    if (marketingCase.ganhoProdutividade != null &&
        marketingCase.ganhoProdutividade!.isNotEmpty) {
      return marketingCase.ganhoProdutividade;
    }
    return null;
  }

  static String _moneyCompact(double value) {
    final absValue = value.abs();
    final prefix = value < 0 ? '-' : '';
    if (absValue >= 1000) {
      final compact = (absValue / 1000).toStringAsFixed(1).replaceAll('.', ',');
      return '${prefix}R\$$compact mil';
    }
    return '${prefix}R\$${absValue.toStringAsFixed(0)}';
  }

  static String _signed(double value) {
    final formatted = value.toStringAsFixed(1).replaceAll('.', ',');
    return value >= 0 ? '+$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final tier = marketingCase.visibilidade;
    final w = pinWidth(tier);
    final h = pinHeight(tier);
    final border = _borderWidth(tier);
    final borderColor = _borderColor(tier);
    final resultText = _resultText();
    final media = MarketingCaseMedia.mediaRefs(marketingCase);
    const pointerH = 10.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: 'Case de Marketing: ${marketingCase.produtoUtilizado}',
        button: true,
        child: SizedBox(
          width: w,
          height: h + pointerH,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    border: Border.all(color: borderColor, width: border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10 - border),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildPhoto(tier, media),
                        if (media.length > 1)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${media.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _InfoBar(
                            produto: marketingCase.produtoUtilizado,
                            resultText: resultText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(16, pointerH),
                painter: _PointerPainter(color: borderColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(PlanoMarketing tier, List<String> media) {
    if (media.isEmpty) {
      return _PlaceholderPin(tier: tier);
    }
    return ColoredBox(
      color: _placeholderColor(tier),
      child: MarketingMediaImage(
        source: media.first,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_) => _PlaceholderPin(tier: tier),
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  final String produto;
  final String? resultText;

  const _InfoBar({required this.produto, this.resultText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              produto,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (resultText != null) ...[
            const SizedBox(width: 3),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  resultText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderPin extends StatelessWidget {
  final PlanoMarketing tier;

  const _PlaceholderPin({required this.tier});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MarketingCaseMarker._placeholderColor(tier),
      child: Center(
        child: Icon(
          Icons.agriculture,
          color: MarketingCaseMarker._borderColor(tier).withValues(alpha: 0.8),
          size: 24,
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
