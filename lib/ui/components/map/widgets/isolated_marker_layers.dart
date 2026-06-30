import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/publicacao.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/marketing/presentation/providers/marketing_providers.dart';
import '../../../../modules/marketing/domain/enums/plano_marketing.dart';
import '../../../../modules/marketing/presentation/widgets/marketing_case_marker.dart';
import '../../../../modules/marketing/presentation/widgets/marketing_case_sheet.dart';
import '../providers/marker_providers.dart';

/// 🔒 WIDGET 100% ISOLADO: Markers de Publicações
///
/// Otimizações:
/// ✅ Observa SOMENTE publicationMarkersProvider
/// ✅ Não rebuilda por GPS movement
/// ✅ Não rebuilda por zoom
/// ✅ Não rebuilda por pan
/// ✅ Não rebuilda por loading/error state
/// ✅ Markers pré-calculados no provider
/// ✅ Lista imutável
class IsolatedPublicationMarkersLayer extends ConsumerWidget {
  const IsolatedPublicationMarkersLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 OBSERVA SOMENTE markers finais (não publicacoesDataProvider inteiro)
    final markers = ref.watch(publicationMarkersProvider);

    // Se showMarkers = false, não renderizar
    final showMarkers = ref.watch(showMarkersProvider);
    if (!showMarkers) {
      return const SizedBox.shrink();
    }

    // Markers já vêm prontos, apenas renderizar
    return MarkerLayer(markers: markers);
  }
}

/// 🔒 WIDGET 100% ISOLADO: Markers de Ocorrências
///
/// Mesmas otimizações de IsolatedPublicationMarkersLayer
class IsolatedOccurrenceMarkersLayer extends ConsumerWidget {
  final void Function(Occurrence) onOccurrenceTap;

  const IsolatedOccurrenceMarkersLayer({
    super.key,
    required this.onOccurrenceTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 OBSERVA SOMENTE markers finais
    final markers = ref.watch(occurrenceMarkersProvider(onOccurrenceTap));

    final showMarkers = ref.watch(showMarkersProvider);
    if (!showMarkers) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(markers: markers);
  }
}

/// 🔒 WIDGET 100% ISOLADO: Markers de Publicações Locais
///
/// Para uso com estado local (ex: _publicacoes em PrivateMapScreen)
class IsolatedLocalPublicationMarkersLayer extends ConsumerWidget {
  final List<Publicacao> localPublications;

  const IsolatedLocalPublicationMarkersLayer({
    super.key,
    required this.localPublications,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Criar lista de markers via provider
    final markers = ref.watch(
      localPublicationMarkersProvider(localPublications),
    );

    final showMarkers = ref.watch(showMarkersProvider);
    if (!showMarkers) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(markers: markers);
  }
}

/// 🔒 WIDGET 100% ISOLADO: Markers de Marketing Cases
///
/// Sprint 8 — Performance: elimina duplo ref.watch(marketingCasesProvider)
/// no build() do PrivateMapScreen (~420 linhas).
///
/// Visibilidade por zoom (diâmetro de cobertura por tier):
///   Ouro   → zoom ≥ 6.0  (500 km de diâmetro)
///   Prata  → zoom ≥ 7.5  (300 km de diâmetro)
///   Bronze → zoom ≥ 9.0  (200 km de diâmetro / raio 100 km)
///
/// Otimizações:
/// ✅ Observa SOMENTE marketingCasesProvider.select (published + ativo)
/// ✅ Não rebuilda o mapa inteiro quando cases mudam
/// ✅ Filtra e ordena dentro do widget isolado
/// ✅ Rebuild apenas se a lista filtrada mudar
class IsolatedMarketingMarkersLayer extends ConsumerWidget {
  const IsolatedMarketingMarkersLayer({super.key});

  // Zoom mínimo por tier — calibrado para cobertura em tela ~400px de largura
  static const double _zoomMinOuro   = 6.0;  // ~500 km visível
  static const double _zoomMinPrata  = 7.5;  // ~300 km visível
  static const double _zoomMinBronze = 9.0;  // ~200 km visível

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMarkers = ref.watch(showMarkersProvider);
    if (!showMarkers) return const SizedBox.shrink();

    // Zoom atual da câmera do mapa (causa rebuild ao cruzar threshold)
    final currentZoom = MapCamera.of(context).zoom;

    final cases = ref.watch(
      marketingCasesProvider.select((async) {
        if (!async.hasValue) return <dynamic>[];
        return async.value!
            .where(
              (c) =>
                  c.status.toValue() == 'published' &&
                  c.ativo &&
                  c.deletadoEm == null,
            )
            .toList()
          ..sort(
            (a, b) => b.visibilidade.index.compareTo(a.visibilidade.index),
          );
      }),
    );

    if (cases.isEmpty) return const SizedBox.shrink();

    // Filtro por zoom: cada tier tem um raio mínimo de visibilidade
    final visibleCases = cases.where((c) {
      final tier = (c.visibilidade as PlanoMarketing);
      return switch (tier) {
        PlanoMarketing.ouro   => currentZoom >= _zoomMinOuro,
        PlanoMarketing.prata  => currentZoom >= _zoomMinPrata,
        PlanoMarketing.bronze => currentZoom >= _zoomMinBronze,
      };
    }).toList(growable: false);

    if (visibleCases.isEmpty) return const SizedBox.shrink();

    return MarkerLayer(
      markers: visibleCases
          .map(
            (mCase) => Marker(
              key: ValueKey('mkt_${mCase.id}'),
              point: LatLng(mCase.lat, mCase.lng),
              width: MarketingCaseMarker.pinWidth(mCase.visibilidade),
              height: MarketingCaseMarker.pinHeight(mCase.visibilidade) + 10,
              alignment: Alignment.bottomCenter,
              child: MarketingCaseMarker(
                marketingCase: mCase,
                onTap: () {
                  HapticFeedback.lightImpact();
                  MarketingCaseSheet.show(context, mCase);
                },
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// 🔒 WIDGET 100% ISOLADO: Layer de Localização GPS
///
/// Única layer que DEVE rebuildar com GPS movement
///
/// Arquitetura:
/// LocationService → locationStreamProvider → IsolatedUserLocationLayer
///
/// Performance:
/// - Observa SOMENTE locationStreamProvider (stream)
/// - Campo parado: 0 rebuilds
/// - Movimento <5m: 0 rebuilds
/// - Movimento >5m: 1 rebuild (somente este widget)
///
/// Garantias:
/// ✅ Não rebuilda MapRoot
/// ✅ Não rebuilda outras MarkerLayers
/// ✅ Não rebuilda PolygonLayers
/// ✅ Stream real do sistema (não polling)
class IsolatedUserLocationLayer extends ConsumerWidget {
  const IsolatedUserLocationLayer({super.key});

  Widget _buildLocationMarker({required double accuracy}) {
    const baseBlue = Color(0xFF2196F3);
    final ringSize = (48 + (accuracy / 12)).clamp(48, 64).toDouble();

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseBlue.withValues(alpha: 0.15),
            border: Border.all(
              color: baseBlue.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: baseBlue.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseBlue,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 OBSERVA SOMENTE locationStreamProvider (stream reativo)
    final locationAsync = ref.watch(locationStreamProvider);

    return locationAsync.when(
      data: (userPosition) {
        // Stream emitiu nova posição
        return MarkerLayer(
          markers: [
            Marker(
              key: const ValueKey('user_location'),
              point: userPosition,
              width: 64,
              height: 64,
              child: _buildLocationMarker(accuracy: 12),
            ),
          ],
        );
      },
      loading: () {
        // Aguardando primeiro emit do stream
        return const SizedBox.shrink();
      },
      error: (error, stack) {
        // Stream emitiu erro (GPS desabilitado, permissão negada, etc)
        return const SizedBox.shrink();
      },
    );
  }
}
