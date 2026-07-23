import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
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
    PlanoMarketing.ouro => 120,
    PlanoMarketing.prata => 100,
    PlanoMarketing.bronze => 84,
  };

  static double pinHeight(PlanoMarketing tier) => switch (tier) {
    PlanoMarketing.ouro => 100,
    PlanoMarketing.prata => 84,
    PlanoMarketing.bronze => 70,
  };

  // Zoom mínimo por tier. Ouro aparece antes; Prata e Bronze exigem
  // aproximação progressiva para não poluir o mapa em visão regional.
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

  String? _primaryPhotoUrl() {
    final url = switch (marketingCase.tipo) {
      CaseTipo.resultado => marketingCase.fotoPrincipalUrl,
      CaseTipo.antesDepois =>
        marketingCase.fotoDepoisUrl ?? marketingCase.fotoAntesUrl,
      CaseTipo.avaliacao => marketingCase.fotoPrincipalUrl,
    };
    if (url == null || url.trim().isEmpty) return null;
    return url;
  }

  // ─── Resultado/ROI text ───────────────────────────────────────
  String? _resultText() {
    final resultadoRoi = marketingCase.computeRoi();
    if (resultadoRoi != null) {
      return 'ROI ${_moneyCompact(resultadoRoi.roiLiquidoRsHa)}/ha';
    }

    final roi = marketingCase.roi;
    if (roi != null && roi.roiCalculado > 0) {
      return 'ROI ${roi.roiCalculado.toStringAsFixed(0)}%';
    }

    if (marketingCase.tipo == CaseTipo.antesDepois &&
        marketingCase.parametros.isNotEmpty) {
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
                    borderRadius: BorderRadius.all(
                      Radius.circular(10 - border),
                    ),
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
                            resultText: resultText,
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
    final url = _primaryPhotoUrl();
    if (url == null) {
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
          color: MarketingCaseMarker._borderColor(tier).withValues(alpha: 0.8),
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
