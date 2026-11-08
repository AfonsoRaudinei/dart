import '../config/cerrado_satellite_overlay.dart';
import 'map_models.dart';

/// Rótulo curto da camada de basemap (pill temporário, offline UI).
String shortBasemapLayerLabel(
  LayerType layer, {
  String? inpeAcquisitionPeriod,
}) {
  switch (layer) {
    case LayerType.standard:
      return 'Mapa';
    case LayerType.satellite:
      return 'Satélite';
    case LayerType.satelliteUpdated:
      final period =
          inpeAcquisitionPeriod ?? CerradoSatelliteOverlay.acquisitionLabel;
      return 'Mapa INPE · $period';
  }
}
