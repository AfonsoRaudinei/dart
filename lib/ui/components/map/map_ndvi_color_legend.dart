import 'package:flutter/material.dart';

/// Faixa compacta do colormap NDVI (RdYlGn), ao lado do raster.
///
/// Recolhida mostra só as três cores. Um toque ou um arrasto horizontal
/// curto abre ou esconde Alto, Intermediário e Baixo.
class MapNdviColorLegend extends StatefulWidget {
  const MapNdviColorLegend({super.key, this.labelsToTheRight = true});

  /// Texto à direita dos blocos. No mapa isso é a legenda à esquerda do raster.
  final bool labelsToTheRight;

  static const double swatchWidth = 18;
  static const double blockHeight = 22;
  static const double verticalPadding = 4;

  /// Altura da faixa recolhida, usada para centralizar no polígono.
  static const double stripHeight = blockHeight * 3 + verticalPadding * 2;

  static const Color alto = Color(0xFF2E7D32);
  static const Color intermediario = Color(0xFFC5D63C);
  static const Color baixo = Color(0xFFF6C445);
  static const Color baixoExtremo = Color(0xFFC62828);

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
          key: Key('map_ndvi_legend_swatch_alto'),
          color: MapNdviColorLegend.alto,
        ),
        _NdviLegendSwatch(
          key: Key('map_ndvi_legend_swatch_intermediario'),
          color: MapNdviColorLegend.intermediario,
        ),
        _NdviLegendSwatch(
          key: Key('map_ndvi_legend_swatch_baixo'),
          color: MapNdviColorLegend.baixo,
          redFoot: true,
        ),
      ],
    );
  }
}

class _NdviLegendSwatch extends StatelessWidget {
  const _NdviLegendSwatch({
    super.key,
    required this.color,
    this.redFoot = false,
  });

  final Color color;
  final bool redFoot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MapNdviColorLegend.swatchWidth,
      height: MapNdviColorLegend.blockHeight,
      child: redFoot
          ? Column(
              children: [
                Expanded(child: ColoredBox(color: color)),
                const SizedBox(
                  height: 5,
                  width: double.infinity,
                  child: ColoredBox(color: MapNdviColorLegend.baixoExtremo),
                ),
              ],
            )
          : ColoredBox(color: color),
    );
  }
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
          _NdviLegendLabel('Alto', align: align),
          _NdviLegendLabel('Intermediário', align: align),
          _NdviLegendLabel('Baixo', align: align),
        ],
      ),
    );
  }
}

class _NdviLegendLabel extends StatelessWidget {
  const _NdviLegendLabel(this.text, {required this.align});

  final String text;
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
          style: const TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
