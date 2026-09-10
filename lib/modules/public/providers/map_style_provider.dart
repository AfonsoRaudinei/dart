import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/config/map_config.dart';

part 'map_style_provider.g.dart';

/// Provider legado do estilo de mapa no mapa público.
///
/// Tiles da vitrine vêm de [MapConfig.tileConfigForPublicMap], não deste
/// provider. Default OSM para não ressuscitar Carto Voyager se alguém ainda
/// watchar.
@riverpod
class PublicMapStyle extends _$PublicMapStyle {
  @override
  MapStyle build() {
    return MapStyle.standard;
  }

  /// Altera o estilo do mapa
  void changeStyle(MapStyle newStyle) {
    state = newStyle;
  }

  /// Retorna para o estilo padrão
  void resetToDefault() {
    state = MapStyle.standard;
  }

  /// Alterna para fallback (OpenStreetMap)
  void useFallback() {
    state = MapStyle.standard;
  }
}

/// Estado de carregamento de tiles (para debug/monitoramento)
@riverpod
class TileLoadingState extends _$TileLoadingState {
  @override
  TileStatus build() {
    return TileStatus.idle;
  }

  void setLoading() => state = TileStatus.loading;
  void setLoaded() => state = TileStatus.loaded;
  void setError() => state = TileStatus.error;
}

enum TileStatus { idle, loading, loaded, error }
