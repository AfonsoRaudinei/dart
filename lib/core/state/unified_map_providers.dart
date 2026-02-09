import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/field_map_entity.dart';
import '../domain/field_map_adapter.dart';
import '../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../modules/drawing/presentation/providers/drawing_provider.dart';

/// Provider intermediário para otimização de cache.
/// Converte Talhões (Consultoria) em Entidades de Mapa.
/// Separado para evitar reprocessamento quando apenas o desenho muda.
final consultoriaMapEntitiesProvider =
    FutureProvider.autoDispose<List<FieldMapEntity>>((ref) async {
      final fields = await ref.watch(mapFieldsProvider.future);
      // Otimização: Mapeamento isolado. Se 'mapFieldsProvider' não mudar, este resultado é cacheado.
      return fields.map((f) => FieldMapAdapter.fromTalhao(f)).toList();
    });

/// Provider intermediário para features de desenho.
/// Reage a mudanças no DrawingController (frequentes durante edição/salvamento).
final drawingMapEntitiesProvider = Provider.autoDispose<List<FieldMapEntity>>((
  ref,
) {
  final features = ref.watch(drawingFeaturesProvider);
  return features.map((f) => FieldMapAdapter.fromDrawingFeature(f)).toList();
});

/// Provider centralizado para todas as entidades visuais do mapa.
/// Combina fontes diversas (Consultoria, Desenho, Importação) em um único fluxo.
/// Otimizado para recompor listas sem reprocessar parsing pesado.
final unifiedMapEntitiesProvider = FutureProvider.autoDispose<List<FieldMapEntity>>((
  ref,
) async {
  // 1. Obtém dados cacheados de Consultoria
  // Se falhar o carregamento inicial, retorna lista vazia para não bloquear o mapa todo?
  // Por enquanto, propaga o estado de loading/error.
  final consultoria = await ref.watch(consultoriaMapEntitiesProvider.future);

  // 2. Obtém dados de Desenho (Síncrono/Rápido)
  final desenho = ref.watch(drawingMapEntitiesProvider);

  // 3. Combinação
  // Desenhos aparecem sobre talhões de consultoria (ordem de pintura: último = topo)
  return [...consultoria, ...desenho];
});
