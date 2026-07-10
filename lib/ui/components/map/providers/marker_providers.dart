import 'package:flutter/material.dart';
import '../../../../core/design/sf_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/publicacao.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';

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

      final markers = occurrences
          .map((occ) {
            final coords = occ.getCoordinates();
            if (coords == null) return null;

            return Marker(
              key: ValueKey('occ_${occ.id}'),
              point: LatLng(coords['lat']!, coords['long']!),
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => onTap(occ),
                child: _OccurrencePin(occurrence: occ),
              ),
            );
          })
          .whereType<Marker>()
          .toList(growable: false);

      return markers;
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

/// Widget Pin de Ocorrência (leve e stateless)
///
/// Cor de fundo: categoria agronômica (diferencia doença, pragas, daninhas…).
/// Bolinha no canto: urgência (alta/média/baixa).
class _OccurrencePin extends StatelessWidget {
  final Occurrence occurrence;

  const _OccurrencePin({required this.occurrence});

  static Color _colorForCategory(String? category) {
    return OccurrenceCategory.fromString(category).markerColor;
  }

  static Color _colorForUrgency(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'alta':
        return const Color(0xFFFF3B30);
      case 'baixa':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  static IconData _iconForCategory(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'doenca':
      case 'doença':
        return Icons.coronavirus_outlined;
      case 'insetos':
      case 'pragas':
        return Icons.bug_report_outlined;
      case 'daninhas':
      case 'ervas_daninhas':
      case 'ervas daninhas':
        return Icons.grass_outlined;
      case 'nutricional':
      case 'nutrientes':
        return Icons.science_outlined;
      case 'agua':
      case 'água':
        return Icons.water_drop_outlined;
      case 'amostra_solo':
      case 'amostra solo':
        return Icons.biotech_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _colorForCategory(occurrence.category);
    final urgencyColor = _colorForUrgency(occurrence.type);
    final icon = _iconForCategory(occurrence.category);
    final isDraft = occurrence.status == 'draft';
    final opacity = isDraft ? 0.65 : 1.0;

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: opacity),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: opacity),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: opacity),
              size: 18,
            ),
          ),
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: urgencyColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
