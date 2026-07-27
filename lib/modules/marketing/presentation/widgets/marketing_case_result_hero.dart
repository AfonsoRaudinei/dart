import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/case_tipo.dart';
import 'marketing_media_image.dart';

/// Hero de resultado do pin marketing (público + autenticado).
///
/// Full-bleed: imagem(ns) no topo, produto, ROI/resultado, localização
/// inline com ação "Ver no mapa" — sem lat/long crua (designer rules).
class MarketingCaseResultHero extends StatefulWidget {
  final MarketingCase marketingCase;

  const MarketingCaseResultHero({super.key, required this.marketingCase});

  @override
  State<MarketingCaseResultHero> createState() =>
      _MarketingCaseResultHeroState();
}

class _MarketingCaseResultHeroState extends State<MarketingCaseResultHero> {
  final _pageController = PageController();
  int _pageIndex = 0;

  MarketingCase get _case => widget.marketingCase;

  List<String> get _photos {
    switch (_case.tipo) {
      case CaseTipo.antesDepois:
        return [
          if (_case.fotoAntesUrl != null && _case.fotoAntesUrl!.trim().isNotEmpty)
            _case.fotoAntesUrl!,
          if (_case.fotoDepoisUrl != null &&
              _case.fotoDepoisUrl!.trim().isNotEmpty)
            _case.fotoDepoisUrl!,
        ];
      case CaseTipo.resultado:
      case CaseTipo.avaliacao:
        final principal = _case.fotoPrincipalUrl?.trim();
        if (principal != null && principal.isNotEmpty) return [principal];
        return const [];
    }
  }

  List<String> get _photoLabels {
    if (_case.tipo == CaseTipo.antesDepois && _photos.length == 2) {
      return const ['Antes', 'Depois'];
    }
    return const [];
  }

  String? get _resultadoTexto {
    final roi = _case.computeRoi();
    if (roi != null) {
      return 'ROI ${_money(roi.roiLiquidoRsHa)}/ha';
    }
    if (_case.tipo == CaseTipo.antesDepois && _case.parametros.isNotEmpty) {
      final g = _case.mediaGanhoPercent;
      final formatted = g.toStringAsFixed(1).replaceAll('.', ',');
      return g >= 0 ? '+$formatted%' : '$formatted%';
    }
    if (_case.ganhoProdutividade != null &&
        _case.ganhoProdutividade!.trim().isNotEmpty) {
      return _case.ganhoProdutividade;
    }
    if (_case.produtividadeValor != null) {
      final u = _case.produtividadeUnidade?.toValue() ?? '';
      return '${_case.produtividadeValor!.toStringAsFixed(1)} $u'.trim();
    }
    return null;
  }

  String _money(double value) {
    final absValue = value.abs();
    final prefix = value < 0 ? '-' : '';
    if (absValue >= 1000) {
      final compact = (absValue / 1000).toStringAsFixed(1).replaceAll('.', ',');
      return '${prefix}R\$$compact mil';
    }
    return '${prefix}R\$${absValue.toStringAsFixed(0)}';
  }

  void _openMapFocus() {
    final lat = _case.lat;
    final lng = _case.lng;
    context.go(
      '/map?modo=foco&lat=${lat.toStringAsFixed(6)}&lng=${lng.toStringAsFixed(6)}',
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    final resultado = _resultadoTexto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photos.isNotEmpty) _buildHeroMedia(photos),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _case.produtoUtilizado,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: SoloForteSheetTokens.inputText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (resultado != null) ...[
                const SizedBox(height: 8),
                Text(
                  resultado,
                  style: const TextStyle(
                    color: PremiumTokens.brandGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              InkWell(
                onTap: _openMapFocus,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        SFIcons.pinFill,
                        size: 16,
                        color: SoloForteSheetTokens.inputHint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _case.localizacaoTexto,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: SoloForteSheetTokens.inputHint,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Ver no mapa',
                        style: TextStyle(
                          color: PremiumTokens.brandGreen.withValues(
                            alpha: 0.95,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMedia(List<String> photos) {
    final labels = _photoLabels;
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, index) {
              return MarketingMediaImage(
                source: photos[index],
                fit: BoxFit.cover,
                placeholder: (_) => Container(
                  color: SoloForteSheetTokens.inputBackground,
                  alignment: Alignment.center,
                  child: Text(
                    labels.isNotEmpty && index < labels.length
                        ? labels[index]
                        : 'Sem imagem',
                    style: const TextStyle(
                      color: SoloForteSheetTokens.inputHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
          if (photos.length > 1)
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labels.isNotEmpty && _pageIndex < labels.length
                      ? labels[_pageIndex]
                      : '${_pageIndex + 1}/${photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (photos.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: Row(
                children: List.generate(photos.length, (i) {
                  final active = i == _pageIndex;
                  return Container(
                    width: active ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
