import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
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
            // Occurrence usa lat/long, não latitude/longitude
            if (occ.lat == null || occ.long == null) return null;

            return Marker(
              key: ValueKey('occ_${occ.id}'),
              point: LatLng(occ.lat!, occ.long!),
              width: 40,
              height: 40,
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
/// Ícone: reflete a categoria da ocorrência.
/// Cor: reflete a urgência (campo `type`).
class _OccurrencePin extends StatelessWidget {
  final Occurrence occurrence;

  const _OccurrencePin({required this.occurrence});

  // ── Cor por urgência (campo `type`) ─────────────────────────────────────
  static Color _colorForUrgency(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'alta':
        return const Color(0xFFFF3B30); // iOS Red
      case 'baixa':
        return const Color(0xFF8E8E93); // iOS Gray
      default: // 'média' ou outro
        return Colors.orange;
    }
  }

  // ── Ícone por categoria (campo `category`) ──────────────────────────────
  // ❌ SFIcons.warning proibido para marcadores de ocorrência
  static IconData _iconForCategory(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'doenca':
      case 'doença':
        return SFIcons.coronavirus;
      case 'insetos':
      case 'pragas':
        return SFIcons.bugReport;
      case 'daninhas':
      case 'ervas_daninhas':
      case 'ervas daninhas':
        return SFIcons.grass;
      case 'nutricional':
      case 'nutrientes':
        return SFIcons.science;
      case 'agua':
      case 'água':
        return SFIcons.waterDrop;
      case 'amostra_solo':
      case 'amostra solo':
        return Icons.biotech_outlined;
      default:
        return SFIcons.locationOn; // genérico — nunca warning
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForUrgency(occurrence.type);
    final icon = _iconForCategory(occurrence.category);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
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
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
