import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/consultoria/services/talhao_map_adapter.dart';
import '../utils/field_hit_index.dart';

/// Índice espacial de talhões do mapa — reconstruído só quando a lista muda.
final fieldHitIndexProvider = Provider.autoDispose<FieldHitIndex?>((ref) {
  final fields = ref.watch(mapFieldsProvider).valueOrNull;
  if (fields == null || fields.isEmpty) return null;

  final entries = <({String id, Map<String, dynamic> geometry})>[];
  for (final field in fields) {
    final geometry = field.geometry;
    if (geometry == null || geometry.isEmpty) continue;
    final sample = TalhaoMapAdapter.boundsSamplePoints(field);
    if (sample.length < 3) continue;
    entries.add((id: field.id, geometry: geometry));
  }
  if (entries.isEmpty) return null;
  return FieldHitIndex(entries: entries);
});
