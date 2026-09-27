import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import '../../domain/enums/plano_marketing.dart';

/// Pin rico para o mapa — exibe foto, produto e ROI por tier.
///
/// ADR-011: hierarquia visual Ouro > Prata > Bronze.
///
/// Call sites devem usar `Alignment.topCenter` no [Marker]: no flutter_map 7
/// isso posiciona o widget acima do ponto, deixando o ponteiro (base do pin)
/// sobre a coordenada. Também preferir `MarkerLayer(rotate: true)` para o pin
/// permanecer vertical se a câmera rotacionar.
class MarketingCaseMarker extends StatelessWidget {
  final MarketingCase marketingCase;
  final VoidCallback onTap;

  /// Zoom do mapa. `0` (desconhecido) mantém o pin compacto.
  final double zoom;

  const MarketingCaseMarker({
    super.key,
    required this.marketingCase,
    required this.onTap,
    this.zoom = 0,
  });

  /// A partir daqui o pin vira cartão de leitura (nome 15 px, resultado 14 px).
  /// Longe disso o pin compacto continua igual — a foto é o marco.
  static const double readingZoom = 15;

  static const double readingPinWidth = 184;
  static const double readingPhotoHeight = 96;

  /// 6+15+4+18+6: padding, nome (height 1), vão, pílula do resultado, padding.
  static const double readingBarHeight = 49;
  static const double pointerHeight = 10;

  static const double compactNameFontSize = 8;
  static const double compactResultFontSize = 7;
  static const double readingNameFontSize = 15;
  static const double readingResultFontSize = 14;

  static bool isReadingZoom(double zoom) => zoom >= readingZoom;

  // ─── Dimensões por tier ───────────────────────────────────────
  /// Corpo do pin, sem o ponteiro. Call sites somam [pointerHeight].
  static double pinWidth(PlanoMarketing tier, {double zoom = 0}) {
    if (isReadingZoom(zoom)) return readingPinWidth;
    return switch (tier) {
      PlanoMarketing.ouro => 120,
      PlanoMarketing.prata => 100,
      PlanoMarketing.bronze => 84,
    };
  }

  static double pinHeight(PlanoMarketing tier, {double zoom = 0}) {
    if (isReadingZoom(zoom)) {
      return readingPhotoHeight + readingBarHeight + 2 * _borderWidth(tier);
    }
    return switch (tier) {
      PlanoMarketing.ouro => 100,
      PlanoMarketing.prata => 84,
      PlanoMarketing.bronze => 70,
    };
  }

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
      // Compacto no pin (Prata=100px): sem prefixo "ROI " para caber o valor.
      return '${_moneyCompact(resultadoRoi.roiLiquidoRsHa)}/ha';
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
    final reading = isReadingZoom(zoom);
    final w = pinWidth(tier, zoom: zoom);
    final h = pinHeight(tier, zoom: zoom);
    final border = _borderWidth(tier);
    final borderColor = _borderColor(tier);
    final resultText = _resultText();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: 'Case de Marketing: ${marketingCase.produtoUtilizado}',
        button: true,
        child: SizedBox(
          width: w,
          height: h + pointerHeight,
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
                    child: reading
                        ? _readingBody(tier, resultText)
                        : _compactBody(tier, resultText),
                  ),
                ),
              ),

              // ── Ponteiro triangular ───────────────────────────
              CustomPaint(
                size: const Size(16, pointerHeight),
                painter: _PointerPainter(color: borderColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Foto em tela cheia e faixa sobreposta. O texto cabe pequeno de propósito.
  Widget _compactBody(PlanoMarketing tier, String? resultText) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPhoto(tier),
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
    );
  }

  /// Foto com a altura de hoje e a faixa abaixo, em duas linhas legíveis.
  /// A borda do container come 2× a espessura; [pinHeight] já reserva isso.
  Widget _readingBody(PlanoMarketing tier, String? resultText) {
    return Column(
      children: [
        SizedBox(
          height: readingPhotoHeight,
          width: double.infinity,
          child: _buildPhoto(tier),
        ),
        SizedBox(
          height: readingBarHeight,
          width: double.infinity,
          child: _InfoBar(
            produto: marketingCase.produtoUtilizado,
            resultText: resultText,
            reading: true,
          ),
        ),
      ],
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
  final bool reading;

  const _InfoBar({
    required this.produto,
    this.resultText,
    this.reading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reading) return _readingBar();
    return _compactBar();
  }

  Widget _compactBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65)),
      child: Row(
        children: [
          // Produto cede espaço; badge do resultado tem prioridade visual.
          Flexible(
            child: Text(
              produto,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: MarketingCaseMarker.compactNameFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (resultText != null) ...[
            const SizedBox(width: 3),
            // Largura intrínseca: não ellipsiza o valor (bug Prata: só "ROI").
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                resultText!,
                softWrap: false,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: MarketingCaseMarker.compactResultFontSize,
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

  /// Nome numa linha, resultado na de baixo. A altura fecha com
  /// [MarketingCaseMarker.readingBarHeight] para o Marker não cortar.
  Widget _readingBar() {
    return Container(
      height: MarketingCaseMarker.readingBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            produto,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: MarketingCaseMarker.readingNameFontSize,
              height: 1,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (resultText != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                resultText!,
                softWrap: false,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: MarketingCaseMarker.readingResultFontSize,
                  height: 1,
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
