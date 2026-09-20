import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'satellite_freshness_policy.dart';

/// Configuração da camada WMS INPE para satélite Cerrado (Sentinel-2).
class CerradoSatelliteOverlay {
  const CerradoSatelliteOverlay._();

  static const wmsBaseUrl =
      'https://data.inpe.br/bdc/geoserver/mosaics/ows';
  static const layerName = 'mosaic-s2-cerrado-2m';
  static const acquisitionLabel = 'nov/2023 – ago/2024';
  static const defaultOpacity = 1.0;
  static const wmsFormat = 'image/png';
  static const wmsVersion = '1.1.1';
  static const wmsCrs = 'EPSG:3857';
  /// Tiles transparentes evitam ocultar satélite offline/cache quando WMS falha.
  static const wmsTransparent = true;

  /// Limite geográfico do mosaico INPE — restringe pedidos WMS ao bioma Cerrado.
  static LatLngBounds get tileBounds => LatLngBounds(
    const LatLng(kCerradoSouth, kCerradoWest),
    const LatLng(kCerradoNorth, kCerradoEast),
  );

  /// Retorna `true` quando o ponto está dentro do bbox do overlay Cerrado.
  static bool isWithinBounds(double lat, double lng) =>
      isInCerradoBounds(lat, lng);
}
