import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/map_models.dart';
import '../data/map_repository.dart';

part 'map_state.g.dart';

@Riverpod(keepAlive: true)
MapRepository mapRepository(Ref ref) {
  return MapRepository();
}

// State for active layer type
@Riverpod(keepAlive: true)
class ActiveLayer extends _$ActiveLayer {
  static const _kLayerKey = 'map_active_layer';

  @override
  LayerType build() {
    _loadPersistedLayer();
    return LayerType.standard;
  }

  Future<void> _loadPersistedLayer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLayerKey);
      if (saved != null) {
        final verify = LayerType.values.firstWhere(
          (e) => e.toString() == saved,
          orElse: () => LayerType.standard,
        );
        if (verify != state) {
          state = verify;
        }
      }
    } catch (_) {}
  }

  void setLayer(LayerType type) {
    state = type;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_kLayerKey, type.toString());
    });
  }
}

// State for markers toggle
@Riverpod(keepAlive: true)
class ShowMarkers extends _$ShowMarkers {
  @override
  bool build() {
    return true;
  }

  void toggle() {
    state = !state;
  }
}

// State for publications data
@Riverpod(keepAlive: true)
class PublicationsData extends _$PublicationsData {
  @override
  Future<List<Publication>> build() async {
    final repo = ref.read(mapRepositoryProvider);
    return repo.fetchPublications();
  }
}
