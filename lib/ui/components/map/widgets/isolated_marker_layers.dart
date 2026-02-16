import 'package:flutter/material.dart';
import '../../../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/publicacao.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
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
              width: 60,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.blue, width: 3),
                ),
                child: const Center(
                  child: Icon(SFIcons.myLocation, color: Colors.blue, size: 24),
                ),
              ),
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
