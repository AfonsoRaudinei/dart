import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/config/map_config.dart';

part 'map_style_provider.g.dart';

/// Provider do estilo de mapa ativo no mapa público.
///
/// Permite alternar entre diferentes estilos de mapa
/// com design iOS-like e fallback automático.
@riverpod
class PublicMapStyle extends _$PublicMapStyle {
  @override
  MapStyle build() {
    // Estilo padrão: Carto Voyager (iOS-like)
    return MapStyle.iosLight;
  }

  /// Altera o estilo do mapa
  void changeStyle(MapStyle newStyle) {
    state = newStyle;
  }

  /// Retorna para o estilo padrão
  void resetToDefault() {
    state = MapStyle.iosLight;
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
