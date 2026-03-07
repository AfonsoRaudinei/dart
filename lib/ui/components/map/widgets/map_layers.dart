import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/map_models.dart';
import '../../../../core/config/map_config.dart';

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
  /// [LayerType.terrain]  → OpenTopoMap (topográfico com curvas de nível)
  String _getLayerUrl(LayerType type) {
    switch (type) {
      case LayerType.satellite:
        // 🛰️ SATÉLITE: Google Maps Hybrid (lyrs=y)
        // Migrado de ESRI World Imagery para Google Maps Satellite.
        // Cobertura superior no Brasil rural, zoom até 20+.
        // Subdomínios 0-3 em MapConfig.googleSatelliteSubdomains.
        return MapConfig.googleSatelliteUrl;
      case LayerType.terrain:
        return 'https://b.tile.opentopomap.org/{z}/{x}/{y}.png';
      case LayerType.standard:
        // 🎨 ESTILO PADRÃO (Apple Maps / iOS Replica): Carto Voyager
        // Possui cores pastéis claras, águas azul-marinho puras e vegetação sutil,
        // exatamente como o sistema nativo da Apple na visualização "Explorar".
        return MapConfig.cartoVoyager;
    }
  }

  List<String> _getSubdomains(LayerType type) {
    switch (type) {
      case LayerType.satellite:
        return MapConfig.googleSatelliteSubdomains;
      case LayerType.standard:
        return MapConfig.cartoSubdomains;
      case LayerType.terrain:
        return const ['a', 'b', 'c'];
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
