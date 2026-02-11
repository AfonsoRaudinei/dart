import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/map_models.dart';
import '../domain/publicacao.dart';
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

// State for publications data (Legacy — @deprecated)
@Deprecated('Use PublicacoesData instead — ADR-007')
@Riverpod(keepAlive: true)
class PublicationsData extends _$PublicationsData {
  @override
  Future<List<Publication>> build() async {
    final repo = ref.read(mapRepositoryProvider);
    // ignore: deprecated_member_use_from_same_package
    return repo.fetchPublications();
  }
}

// State for publicações data (Canonical — ADR-007)
@Riverpod(keepAlive: true)
class PublicacoesData extends _$PublicacoesData {
  @override
  Future<List<Publicacao>> build() async {
    final repo = ref.read(mapRepositoryProvider);
    return repo.fetchPublicacoes();
  }
}
