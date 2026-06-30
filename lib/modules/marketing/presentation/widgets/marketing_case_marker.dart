import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/plano_marketing.dart';

/// Pin rico para o mapa — exibe foto, produto e ROI por tier.
///
/// ADR-011: hierarquia visual Ouro > Prata > Bronze.
/// Anchor: bottomCenter (ponteiro aponta para a coordenada no mapa).
class MarketingCaseMarker extends StatelessWidget {
  final MarketingCase marketingCase;
  final VoidCallback onTap;

  const MarketingCaseMarker({
    super.key,
    required this.marketingCase,
    required this.onTap,
  });

  // ─── Dimensões por tier ───────────────────────────────────────
  static double pinWidth(PlanoMarketing tier) => switch (tier) {
        PlanoMarketing.ouro   => 120,
        PlanoMarketing.prata  => 100,
        PlanoMarketing.bronze => 84,
      };

  static double pinHeight(PlanoMarketing tier) => switch (tier) {
        PlanoMarketing.ouro   => 100,
        PlanoMarketing.prata  => 84,
        PlanoMarketing.bronze => 70,
      };

  static double _borderWidth(PlanoMarketing tier) => switch (tier) {
        PlanoMarketing.ouro   => 3.0,
        PlanoMarketing.prata  => 2.5,
        PlanoMarketing.bronze => 2.0,
      };

  static Color _borderColor(PlanoMarketing tier) => switch (tier) {
        PlanoMarketing.ouro   => const Color(0xFFFFD700),
        PlanoMarketing.prata  => const Color(0xFFC0C0C0),
        PlanoMarketing.bronze => const Color(0xFFCD7F32),
      };

  static Color _placeholderColor(PlanoMarketing tier) => switch (tier) {
        PlanoMarketing.ouro   => const Color(0xFF2C2400),
        PlanoMarketing.prata  => const Color(0xFF252525),
        PlanoMarketing.bronze => const Color(0xFF1E1200),
      };

  // ─── ROI text ─────────────────────────────────────────────────
  String? _roiText() {
    final roi = marketingCase.roi;
    if (roi != null && roi.roiCalculado > 0) {
      return 'ROI ${roi.roiCalculado.toStringAsFixed(0)}%';
    }
    if (marketingCase.ganhoProdutividade != null &&
        marketingCase.ganhoProdutividade!.isNotEmpty) {
      return marketingCase.ganhoProdutividade;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tier = marketingCase.visibilidade;
    final w = pinWidth(tier);
    final h = pinHeight(tier);
    final border = _borderWidth(tier);
    final borderColor = _borderColor(tier);
    final roiText = _roiText();
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
              // ── Pin body ─────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    border: Border.all(color: borderColor, width: border),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.all(Radius.circular(10 - border)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Foto de fundo
                        _buildPhoto(tier),

                        // 2. Barra inferior: produto + ROI
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _InfoBar(
                            produto: marketingCase.produtoUtilizado,
                            roiText: roiText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Ponteiro triangular ───────────────────────────
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

  Widget _buildPhoto(PlanoMarketing tier) {
    final url = marketingCase.fotoPrincipalUrl;
    if (url == null || url.isEmpty) {
      return _PlaceholderPin(tier: tier);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => _PlaceholderPin(tier: tier),
      errorWidget: (_, __, ___) => _PlaceholderPin(tier: tier),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }
}

// ─── Barra inferior ──────────────────────────────────────────────

class _InfoBar extends StatelessWidget {
  final String produto;
  final String? roiText;

  const _InfoBar({required this.produto, this.roiText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
      ),
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
          if (roiText != null) ...[
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                roiText!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Placeholder ─────────────────────────────────────────────────

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
          color:
              MarketingCaseMarker._borderColor(tier).withValues(alpha: 0.8),
          size: 24,
        ),
      ),
    );
  }
}

// ─── Ponteiro triangular ─────────────────────────────────────────

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
