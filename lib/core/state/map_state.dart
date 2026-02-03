import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  LayerType build() {
    return LayerType.standard;
  }

  void setLayer(LayerType type) {
    state = type;
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
