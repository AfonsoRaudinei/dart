// ADR-030 F3 — Widget extraído de private_map_screen.dart (B7c)
// Camada de polígonos de talhões para o FlutterMap.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/consultoria/services/talhao_map_adapter.dart';

/// Renderiza os polígonos de talhões sobre o mapa.
/// Consome [mapFieldsProvider] e [selectedTalhaoIdProvider] diretamente.
class TalhaoPolygonLayer extends ConsumerWidget {
  const TalhaoPolygonLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapFields = ref.watch(mapFieldsProvider);
    final selectedTalhaoId = ref.watch(selectedTalhaoIdProvider);

    if (!mapFields.hasValue) return const SizedBox.shrink();

    return PolygonLayer(
      polygons: mapFields.value!.map((t) {
        return TalhaoMapAdapter.toPolygon(
          t,
          isSelected: t.id == selectedTalhaoId,
        );
      }).toList(),
    );
  }
}
