import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mosaico Sentinel-2 Brasil 3 meses (true color) — WMS INPE BDC.
class BrazilSatelliteMosaicOverlay {
  const BrazilSatelliteMosaicOverlay._();

  static const wmsBaseUrl =
      'https://data.inpe.br/bdc/geoserver/mosaics/ows';
  static const layerName = 'mosaic-s2-brazil-3m';

  /// Trimestre padrão do GeoServer (GetCapabilities, default TIME).
  static const wmsTimeIso = '2026-04-01T00:00:00.000Z';

  static String get acquisitionLabel =>
      quarterLabelFromTimeIso(wmsTimeIso);

  static const defaultOpacity = 1.0;
  static const wmsFormat = 'image/png';
  static const wmsVersion = '1.1.1';
  static const wmsCrs = 'EPSG:3857';
  static const wmsTransparent = false;

  static LatLngBounds get tileBounds => LatLngBounds(
    const LatLng(-33.751728374753654, -76.01514728790431),
    const LatLng(6.192706565396369, -27.639640416784665),
  );

  static bool isWithinBounds(double lat, double lng) {
    final bounds = tileBounds;
    return lat >= bounds.south &&
        lat <= bounds.north &&
        lng >= bounds.west &&
        lng <= bounds.east;
  }

  /// Converte TIME WMS (início trimestral) em rótulo legível pt-BR.
  static String quarterLabelFromTimeIso(String iso) {
    final dt = DateTime.parse(iso).toUtc();
    final year = dt.year;
    switch (dt.month) {
      case 1:
        return 'jan–mar/$year';
      case 4:
        return 'abr–jun/$year';
      case 7:
        return 'jul–set/$year';
      case 10:
        return 'out–dez/$year';
      default:
        return '${dt.month.toString().padLeft(2, '0')}/$year';
    }
  }
}
