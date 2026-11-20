import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  /// Longe disso o pin compacto mostra a foto na proporção da câmera e a faixa abaixo.
  static const double readingZoom = 15;

  static const double readingPinWidth = 184;

  /// Largura/altura da câmera em pé (3:4).
  static const double portraitAspect = 3 / 4;

  /// Largura/altura da câmera deitada (4:3).
  static const double landscapeAspect = 4 / 3;

  /// 6+15+4+18+6: padding, nome (height 1), vão, pílula do resultado, padding.
  static const double readingBarHeight = 49;
  static const double pointerHeight = 10;

  /// Faixa fixa do pin compacto, abaixo da foto, para o Marker não cortar.
  static const double compactBarHeight = 20;

  /// Proporção largura/altura já medida, por URL da foto.
  static final Map<String, double> _aspectByUrl = {};

  /// Incrementa quando a proporção exibida de alguma foto muda.
  /// Foto em pé (já é o fallback) não incrementa.
  static final ValueNotifier<int> aspectRevision = ValueNotifier<int>(0);

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

  /// Proporção largura/altura do quadro. Fora de [portraitAspect]–[landscapeAspect]
  /// vai para o extremo; valor ausente ou inválido fica em pé.
  static double frameAspect(double? widthOverHeight) {
    if (widthOverHeight == null ||
        widthOverHeight <= 0 ||
        widthOverHeight.isNaN) {
      return portraitAspect;
    }
    return widthOverHeight.clamp(portraitAspect, landscapeAspect).toDouble();
  }

  static double? cachedAspect(String? url) {
    if (url == null) return null;
    return _aspectByUrl[url];
  }

  /// Grava [frameAspect] de [widthOverHeight]. Não notifica se o quadro
  /// exibido (cache anterior, ou [portraitAspect] se ainda não havia) já é esse.
  static void rememberAspect(String url, double widthOverHeight) {
    final next = frameAspect(widthOverHeight);
    final previous = _aspectByUrl[url];
    final displayed = previous ?? portraitAspect;
    _aspectByUrl[url] = next;
    if (displayed == next) return;
    aspectRevision.value++;
  }

  static double pinHeight(
    PlanoMarketing tier, {
    double zoom = 0,
    double? aspect,
  }) {
    final border = _borderWidth(tier);
    final innerW = pinWidth(tier, zoom: zoom) - 2 * border;
    final photoH = innerW / frameAspect(aspect);
    final bar = isReadingZoom(zoom) ? readingBarHeight : compactBarHeight;
    return photoH + bar + 2 * border;
  }

  // Zoom mínimo por tier. Ouro aparece de mais longe; Prata e Bronze exigem
  // aproximação progressiva para não poluir o mapa em visão regional.
  static double minZoomForTier(PlanoMarketing tier) => switch (tier) {
    PlanoMarketing.ouro => 8.0,
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

  /// Resultado/avaliação usam a foto principal. Antes/Depois prefere o depois.
  /// Vazio vira null.
  static String? primaryPhotoUrl(MarketingCase c) {
    final url = switch (c.tipo) {
      CaseTipo.resultado => c.fotoPrincipalUrl,
      CaseTipo.antesDepois => c.fotoDepoisUrl ?? c.fotoAntesUrl,
      CaseTipo.avaliacao => c.fotoPrincipalUrl,
    };
    if (url == null || url.trim().isEmpty) return null;
    return url;
  }

  String? _primaryPhotoUrl() => primaryPhotoUrl(marketingCase);

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
    final photoUrl = _primaryPhotoUrl();
    final w = pinWidth(tier, zoom: zoom);
    final h = pinHeight(tier, zoom: zoom, aspect: cachedAspect(photoUrl));
    final border = _borderWidth(tier);
    final borderColor = _borderColor(tier);
    final resultText = _resultText();

    // Pin de mapa: tamanho fixo em dp. Não segue Dynamic Type (evita overflow na faixa).
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1,
      child: GestureDetector(
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
      ),
    );
  }

  /// Foto na largura inteira do cartão e faixa abaixo. A borda come 2× a
  /// espessura; [pinHeight] reserva isso na altura da foto.
  Widget _compactBody(PlanoMarketing tier, String? resultText) {
    return Column(
      children: [
        Expanded(child: _buildPhoto(tier)),
        SizedBox(
          height: compactBarHeight,
          width: double.infinity,
          child: _InfoBar(
            produto: marketingCase.produtoUtilizado,
            resultText: resultText,
          ),
        ),
      ],
    );
  }

  /// Mesma foto em largura cheia, com a faixa de leitura abaixo.
  /// A borda do container come 2× a espessura; [pinHeight] já reserva isso.
  Widget _readingBody(PlanoMarketing tier, String? resultText) {
    return Column(
      children: [
        Expanded(child: _buildPhoto(tier)),
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
    final placeholder = _PlaceholderPin(tier: tier);
    return MarketingCaseNetworkPhoto(
      url: url,
      placeholder: placeholder,
      errorWidget: placeholder,
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }
}

/// Foto de rede do case. Ao resolver, grava a proporção em [MarketingCaseMarker].
class MarketingCaseNetworkPhoto extends StatefulWidget {
  final String url;
  final Widget? placeholder;
  final Widget errorWidget;
  final BoxFit fit;
  final Alignment alignment;
  final Duration fadeInDuration;

  const MarketingCaseNetworkPhoto({
    super.key,
    required this.url,
    required this.errorWidget,
    this.placeholder,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fadeInDuration = const Duration(milliseconds: 500),
  });

  @override
  State<MarketingCaseNetworkPhoto> createState() =>
      _MarketingCaseNetworkPhotoState();
}

class _MarketingCaseNetworkPhotoState extends State<MarketingCaseNetworkPhoto> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  String? _listenedUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bind(widget.url);
  }

  @override
  void didUpdateWidget(covariant MarketingCaseNetworkPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _bind(widget.url);
  }

  void _bind(String url) {
    if (_listenedUrl == url && _stream != null) return;
    _detach();
    _listenedUrl = url;
    final stream = CachedNetworkImageProvider(
      url,
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) => _remember(url, info),
      onError: (_, __) {},
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _remember(String url, ImageInfo info) {
    final height = info.image.height;
    if (height <= 0) return;
    final ratio = info.image.width / height;
    void store() => MarketingCaseMarker.rememberAspect(url, ratio);
    final phase = WidgetsBinding.instance.schedulerPhase;
    final inFrame =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (inFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) => store());
      return;
    }
    store();
  }

  void _detach() {
    final listener = _listener;
    final stream = _stream;
    if (listener != null && stream != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
    _listenedUrl = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.placeholder;
    return CachedNetworkImage(
      imageUrl: widget.url,
      width: double.infinity,
      height: double.infinity,
      fit: widget.fit,
      alignment: widget.alignment,
      fadeInDuration: widget.fadeInDuration,
      placeholder: placeholder == null ? null : (_, __) => placeholder,
      errorWidget: (_, __, ___) => widget.errorWidget,
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
      height: MarketingCaseMarker.compactBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      alignment: Alignment.centerLeft,
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
                height: 1,
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
