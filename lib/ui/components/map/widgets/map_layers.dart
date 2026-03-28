import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/map_models.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/config/map_secrets.dart';

/// Widget que observa apenas activeLayerProvider e renderiza o TileLayer.
/// Rebuild isolado quando a camada muda.
class MapLayersWidget extends ConsumerWidget {
  const MapLayersWidget({super.key});

  /// Retorna a URL do tile provider para cada tipo de camada.
  ///
  /// [LayerType.standard] → Carto Voyager
  ///   Estilo natural polido (Apple Maps style): cores pastéis claras, águas azuis,
  ///   rodovias limpas — ideal para focar o usuário nas sobreposições do app.
  ///   Paleta baseada na estética de navegação fluida.
  ///
  /// [LayerType.satellite] → Google Maps Satellite Híbrido (lyrs=y)
  ///   Imagem de alta resolução + labels de cidades/rodovias — ideal para campo
  ///
  /// [LayerType.relevo] → MapTiler Landscape
  ///   Mapa topográfico com curvas de nível e visualização de elevação
  String _getLayerUrl(LayerType type) {
    switch (type) {
      case LayerType.satellite:
        // 🛰️ SATÉLITE: Google Maps Hybrid (lyrs=y)
        // Migrado de ESRI World Imagery para Google Maps Satellite.
        // Cobertura superior no Brasil rural, zoom até 20+.
        // Subdomínios 0-3 em MapConfig.googleSatelliteSubdomains.
        return MapConfig.googleSatelliteUrl;
      case LayerType.relevo:
        // 🗻 RELEVO: MapTiler Landscape
        // Estilo topográfico com curvas de nível e sombreamento de relevo.
        // Requer API key via --dart-define=MAPTILER_API_KEY=<key>
        // Free tier: 100k requests/mês
        return MapConfig.mapTilerLandscapeUrl(kMapTilerApiKey);
      case LayerType.standard:
        // 🎨 ESTILO PADRÃO: Stadia Stamen Terrain (com API key injetada via --dart-define)
        // Vegetação verde, água azul, estradas limpas — funciona em produção iOS/TestFlight.
        // API key appended automaticamente por MapConfig.stadiaStamenTerrainUrl.
        return MapConfig.stadiaStamenTerrainUrl;
    }
  }

  List<String> _getSubdomains(LayerType type) {
    switch (type) {
      case LayerType.satellite:
        return MapConfig.googleSatelliteSubdomains;
      case LayerType.standard:
        return MapConfig.cartoSubdomains;
      case LayerType.relevo:
        // MapTiler não usa subdomínios — retorna lista vazia
        return const [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLayer = ref.watch(activeLayerProvider);

    return TileLayer(
      urlTemplate: _getLayerUrl(activeLayer),
      subdomains: _getSubdomains(activeLayer),
      userAgentPackageName: MapConfig.userAgent,
    );
  }
}
