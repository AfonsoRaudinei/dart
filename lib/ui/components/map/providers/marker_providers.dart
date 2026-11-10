import 'package:flutter/material.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/design/sf_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/publicacao.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../screens/map/layers/linked_consultant_field_layer.dart';
import '../occurrence_pins.dart';
import 'package:latlong2/latlong.dart';

/// Nomes de produtor para legendas em pins de área visitada.
final occurrenceAreaVisitadaClientLabelsProvider =
    FutureProvider<Map<String, String>>((ref) async {
      final occurrences = ref.watch(
        occurrencesListProvider.select((asyncOcc) {
          if (!asyncOcc.hasValue) return <Occurrence>[];
          return asyncOcc.value!;
        }),
      );

      final clientIds = <String>{};
      for (final occurrence in occurrences) {
        if (!isAreaVisitadaCategory(occurrence.category)) continue;
        final id = occurrence.clientId?.trim();
        if (id == null || id.isEmpty) continue;
        clientIds.add(id);
      }

      if (clientIds.isEmpty) return const {};

      final lookup = ref.read(clientLookupProvider);
      final linkedNames = <String, String>{
        for (final client
            in ref.watch(linkedConsultantMapClientsProvider).valueOrNull ??
                const [])
          client.link.clientId: client.name.trim(),
      };
      final labels = <String, String>{};
      for (final id in clientIds) {
        final client = await lookup.findById(id);
        final localName = client?.name.trim();
        final linkedName = linkedNames[id];
        final name = (localName != null && localName.isNotEmpty)
            ? localName
            : linkedName;
        if (name != null && name.isNotEmpty) {
          labels[id] = name;
        }
      }
      return labels;
    });

/// 🎯 PROVIDER DERIVADO: Markers de Publicações
///
/// Responsabilidades:
/// - Receber dados brutos (publicações)
/// - Projetar para LatLng
/// - Criar objetos Marker imutáveis
/// - Retornar lista não-growable
///
/// ⚡ Otimização:
/// - Só recalcula quando lista de publicações REALMENTE muda
/// - Não rebuilda por loading state
/// - Não rebuilda por error state
/// - Lista imutável (growable: false)
final publicationMarkersProvider = Provider<List<Marker>>((ref) {
  // Observar apenas o valor final, não AsyncValue completo
  final publications = ref.watch(
    publicacoesDataProvider.select((asyncPubs) {
      if (!asyncPubs.hasValue) return <Publicacao>[];
      return asyncPubs.value!;
    }),
  );

  if (publications.isEmpty) {
    return const []; // Lista const imutável
  }

  // Criar markers uma única vez
  final markers = publications
      .map((pub) {
        return Marker(
          key: ValueKey('pub_${pub.id}'), // Key estável
          point: LatLng(pub.latitude, pub.longitude),
          width: 40,
          height: 40,
          child: _PublicationPin(publication: pub),
        );
      })
      .toList(growable: false); // IMPORTANTE: lista imutável

  return markers;
});

/// 🎯 PROVIDER DERIVADO: Markers de Ocorrências
///
/// Mesmas otimizações de publicationMarkersProvider
final occurrenceMarkersProvider =
    Provider.family<List<Marker>, void Function(Occurrence)>((ref, onTap) {
      final occurrences = ref.watch(
        occurrencesListProvider.select((asyncOcc) {
          if (!asyncOcc.hasValue) return <Occurrence>[];
          return asyncOcc.value!;
        }),
      );

      if (occurrences.isEmpty) {
        return const [];
      }

      final clientLabels =
          ref.watch(occurrenceAreaVisitadaClientLabelsProvider).valueOrNull ??
          const {};

      final projection = OccurrencePinGenerator.projectOccurrences(
        occurrences,
        clientNameById: clientLabels,
      );
      OccurrencePinGenerator.logProjectionDropCounts(
        invalidCount: projection.invalidCount,
        duplicateCount: projection.duplicateCount,
      );

      return OccurrencePinGenerator.buildMarkers(
        markerData: projection.markers,
        onPinTap: onTap,
      );
    });

/// 🎯 PROVIDER DERIVADO: Markers de Publicações Locais
///
/// Para lista local (não AsyncValue)
final localPublicationMarkersProvider =
    Provider.family<List<Marker>, List<Publicacao>>((ref, localPubs) {
      if (localPubs.isEmpty) {
        return const [];
      }

      final markers = localPubs
          .map((pub) {
            return Marker(
              key: ValueKey('local_pub_${pub.id}'),
              point: LatLng(pub.latitude, pub.longitude),
              width: 40,
              height: 40,
              child: _PublicationPin(publication: pub),
            );
          })
          .toList(growable: false);

      return markers;
    });

/// Widget Pin de Publicação (leve e stateless)
class _PublicationPin extends StatelessWidget {
  final Publicacao publication;

  const _PublicationPin({required this.publication});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(SFIcons.article, color: Colors.white, size: 20),
    );
  }
}
