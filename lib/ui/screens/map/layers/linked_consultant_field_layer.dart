import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/services/talhao_map_adapter.dart';
import 'package:soloforte_app/modules/produtor/data/linked_consultant_geometry.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_repository.dart';

import '../../../../core/state/map_state.dart';

/// Talhão do consultor em foco no mapa. Não entra em [selectedTalhaoIdProvider]:
/// esse id abre o talhão local e permitiria tratar a área como editável.
final linkedConsultantFocusFieldIdProvider = StateProvider<String?>(
  (ref) => null,
);

/// Contornos liberados para esta conta, produtor ou outro consultor.
/// Não usa o dashboard da propriedade própria, para não criar cadastro extra.
final linkedConsultantMapClientsProvider =
    FutureProvider.autoDispose<List<ProducerLinkedClient>>((ref) async {
      return ref
          .watch(producerLinkRepositoryProvider)
          .loadLinkedConsultantData();
    });

/// Contorno somente leitura dos talhões do consultor vinculado.
///
/// A fonte é o dashboard do produtor, que relê `fields` no Supabase ao abrir
/// o mapa e quando a tela Minha propriedade puxa para atualizar. O polígono
/// não tem hit de edição: a conta do consultor continua dona da geometria.
class LinkedConsultantFieldLayer extends ConsumerWidget {
  const LinkedConsultantFieldLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients =
        ref.watch(linkedConsultantMapClientsProvider).valueOrNull ?? const [];
    final focusedId = ref.watch(linkedConsultantFocusFieldIdProvider);
    final areaUnit = ref.watch(areaDisplayUnitProvider);
    final labelPrefs = ref.watch(talhaoMapLabelPrefsProvider);
    if (clients.isEmpty) return const SizedBox.shrink();

    final bounds = MapCamera.maybeOf(context)?.visibleBounds;
    final polygons = <Polygon>[];

    for (final client in clients) {
      for (final farm in client.farms) {
        for (final field in farm.fields) {
          polygons.addAll(
            _polygonsFor(
              field,
              isSelected: field.id == focusedId,
              unit: areaUnit,
              labelPrefs: labelPrefs,
              bounds: bounds,
            ),
          );
        }
      }
    }

    if (polygons.isEmpty) return const SizedBox.shrink();
    return PolygonLayer(polygons: polygons);
  }

  List<Polygon> _polygonsFor(
    ProducerLinkedField field, {
    required bool isSelected,
    required AreaDisplayUnit unit,
    required TalhaoMapLabelPrefs labelPrefs,
    required LatLngBounds? bounds,
  }) {
    final geometry = linkedFieldGeometryMap(field.geometryJson);
    if (geometry == null) return const [];

    final talhao = Talhao(
      id: field.id,
      name: field.name,
      areaHa: field.areaHa,
      crop: '',
      harvest: '',
      geometry: geometry,
    );
    final parts = TalhaoMapAdapter.toMapPolygons(
      talhao,
      isSelected: isSelected,
      unit: unit,
      labelPrefs: labelPrefs,
    );
    if (bounds == null) return parts;

    return parts
        .where((polygon) {
          if (polygon.points.isEmpty) return false;
          return _intersectsBounds(polygon.points, bounds);
        })
        .toList(growable: false);
  }

  static bool _intersectsBounds(List<LatLng> points, LatLngBounds bounds) {
    for (final point in points) {
      if (bounds.contains(point)) return true;
    }
    final box = LatLngBounds.fromPoints(points);
    return box.north >= bounds.south &&
        box.south <= bounds.north &&
        box.east >= bounds.west &&
        box.west <= bounds.east;
  }
}
