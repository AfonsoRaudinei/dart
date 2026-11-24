import 'package:flutter/material.dart';

/// Faixa compacta das cinco classes de NDVI, ao lado do raster.
///
/// Recolhida mostra só as cinco cores. Um toque ou um arrasto horizontal
/// curto abre ou esconde Alto, Bom, Intermediário, Baixo e Muito Baixo, cada
/// rótulo na cor da sua classe.
class MapNdviColorLegend extends StatefulWidget {
  const MapNdviColorLegend({super.key, this.labelsToTheRight = true});

  /// Texto à direita dos blocos. No mapa isso é a legenda à esquerda do raster.
  final bool labelsToTheRight;

  static const double swatchWidth = 16;
  static const double blockHeight = 20;
  static const double verticalPadding = 4;

  /// Altura da faixa recolhida, usada para centralizar no polígono.
  static const double stripHeight = blockHeight * 5 + verticalPadding * 2;

  static const Color muitoBaixo = Color(0xFF922300);
  static const Color baixo = Color(0xFFFD6000);
  static const Color intermediario = Color(0xFFFED000);
  static const Color bom = Color(0xFF95DA48);
  static const Color alto = Color(0xFF008B35);

  @override
  State<MapNdviColorLegend> createState() => _MapNdviColorLegendState();
}

class _MapNdviColorLegendState extends State<MapNdviColorLegend> {
  static const double _dragThreshold = 8;

  bool _open = false;
  double _drag = 0;
  bool _dragToggled = false;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    final swatches = const _NdviLegendSwatches();
    final labels = _open
        ? _NdviLegendLabels(againstSwatchesOnTheRight: !widget.labelsToTheRight)
        : null;
    return GestureDetector(
      key: const Key('map_ndvi_legend'),
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      onHorizontalDragStart: (_) {
        _drag = 0;
        _dragToggled = false;
      },
      onHorizontalDragUpdate: (details) {
        if (_dragToggled) return;
        _drag += details.delta.dx;
        if (_drag.abs() < _dragThreshold) return;
        _dragToggled = true;
        _toggle();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1F000000)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 1,
            vertical: MapNdviColorLegend.verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!widget.labelsToTheRight && labels != null) labels,
              swatches,
              if (widget.labelsToTheRight && labels != null) labels,
            ],
          ),
        ),
      ),
    );
  }
}

class _NdviLegendSwatches extends StatelessWidget {
  const _NdviLegendSwatches();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NdviLegendSwatch(
          key: Key('map_ndvi_legend_swatch_muito_baixo'),
          color: MapNdviColorLegend.muitoBaixo,
        ),
        _NdviLegendSwatch(
          key: Key('map_ndvi_legend_swatch_baixo'),
          color: MapNdviColorLegend.baixo,
        ),
        _NdviLegendSwatch(
          key: Key('map_ndvi_legend_swatch_intermediario'),
          color: MapNdviColorLegend.intermediario,
        ),
        _NdviLegendSwatch(
          key: Key('map_ndvi_legend_swatch_bom'),
          color: MapNdviColorLegend.bom,
        ),
        _NdviLegendSwatch(
          key: Key('map_ndvi_legend_swatch_alto'),
          color: MapNdviColorLegend.alto,
        ),
      ],
    );
  }
}

class _NdviLegendSwatch extends StatelessWidget {
  const _NdviLegendSwatch({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MapNdviColorLegend.swatchWidth,
      height: MapNdviColorLegend.blockHeight,
      child: CustomPaint(painter: _NdviLeafPainter(color)),
    );
  }
}

/// Folha da classe: ponta afilada no topo, laterais convexas, base circular e
/// nervura central mais escura que afina em direção à ponta.
class _NdviLeafPainter extends CustomPainter {
  const _NdviLeafPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const pad = 1.0;
    final top = pad;
    final left = pad;
    final right = w - pad;
    final widest = h * 0.62;
    final r = (right - left) / 2;
    final base = widest + r;
    const k = 0.55;

    final leaf = Path()
      ..moveTo(cx, top)
      ..cubicTo(cx + w * 0.16, h * 0.20, right, h * 0.40, right, widest)
      ..cubicTo(right, widest + r * k, cx + r * k, base, cx, base)
      ..cubicTo(cx - r * k, base, left, widest + r * k, left, widest)
      ..cubicTo(left, h * 0.40, cx - w * 0.16, h * 0.20, cx, top)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );

    final hsl = HSLColor.fromColor(color);
    final vein = hsl
        .withLightness((hsl.lightness * 0.75).clamp(0.0, 1.0))
        .toColor();
    final veinTop = h * 0.35;
    const half = 0.35;
    final veinPath = Path()
      ..moveTo(cx, veinTop)
      ..lineTo(cx + half, base)
      ..lineTo(cx - half, base)
      ..close();
    canvas.drawPath(
      veinPath,
      Paint()
        ..color = vein
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_NdviLeafPainter old) => old.color != color;
}

class _NdviLegendLabels extends StatelessWidget {
  const _NdviLegendLabels({required this.againstSwatchesOnTheRight});

  /// Texto à esquerda dos blocos encosta neles pela direita.
  final bool againstSwatchesOnTheRight;

  @override
  Widget build(BuildContext context) {
    final align = againstSwatchesOnTheRight
        ? Alignment.centerRight
        : Alignment.centerLeft;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: againstSwatchesOnTheRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _NdviLegendLabel(
            'Muito Baixo',
            color: MapNdviColorLegend.muitoBaixo,
            align: align,
          ),
          _NdviLegendLabel(
            'Baixo',
            color: MapNdviColorLegend.baixo,
            align: align,
          ),
          _NdviLegendLabel(
            'Intermediário',
            color: MapNdviColorLegend.intermediario,
            align: align,
          ),
          _NdviLegendLabel('Bom', color: MapNdviColorLegend.bom, align: align),
          _NdviLegendLabel(
            'Alto',
            color: MapNdviColorLegend.alto,
            align: align,
          ),
        ],
      ),
    );
  }
}

class _NdviLegendLabel extends StatelessWidget {
  const _NdviLegendLabel(this.text, {required this.color, required this.align});

  final String text;
  final Color color;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MapNdviColorLegend.blockHeight,
      child: Align(
        alignment: align,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
