import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../infra/preferences_service.dart';
import '../services/connectivity_service.dart';
import '../domain/map_models.dart';
import '../domain/publicacao.dart';
import '../data/map_repository.dart';
import '../utils/app_logger.dart';

part 'map_state.g.dart';

@Riverpod(keepAlive: true)
MapRepository mapRepository(Ref ref) {
  return MapRepository(
    ref.watch(preferencesServiceProvider),
    ref.watch(connectivityServiceProvider),
  );
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
      final prefs = ref.read(preferencesServiceProvider);
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
    } catch (e) {
      AppLogger.warning('Falha ao restaurar layer persistida — usando padrão', tag: 'MapState', error: e);
    }
  }

  void setLayer(LayerType type) {
    state = type;
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setString(_kLayerKey, type.toString());
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
