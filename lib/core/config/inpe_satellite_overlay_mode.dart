/// Modo do overlay satélite INPE no mapa (um ícone, três estados).
enum InpeSatelliteOverlayMode {
  off,
  cerradoInpe,
  brazilMosaic;

  /// Próximo estado no ciclo: Off → INPE Cerrado → Brasil 3M → Off.
  InpeSatelliteOverlayMode cycle() {
    switch (this) {
      case InpeSatelliteOverlayMode.off:
        return InpeSatelliteOverlayMode.cerradoInpe;
      case InpeSatelliteOverlayMode.cerradoInpe:
        return InpeSatelliteOverlayMode.brazilMosaic;
      case InpeSatelliteOverlayMode.brazilMosaic:
        return InpeSatelliteOverlayMode.off;
    }
  }

  bool get isActive => this != InpeSatelliteOverlayMode.off;

  String get persisted {
    switch (this) {
      case InpeSatelliteOverlayMode.off:
        return 'off';
      case InpeSatelliteOverlayMode.cerradoInpe:
        return 'cerrado';
      case InpeSatelliteOverlayMode.brazilMosaic:
        return 'brazil';
    }
  }

  static InpeSatelliteOverlayMode fromPersisted(String? raw) {
    switch (raw) {
      case 'cerrado':
        return InpeSatelliteOverlayMode.cerradoInpe;
      case 'brazil':
        return InpeSatelliteOverlayMode.brazilMosaic;
      case 'off':
      default:
        return InpeSatelliteOverlayMode.off;
    }
  }

  /// Label curto no hint temporário (long-press / pós-toque).
  String get shortLabel {
    switch (this) {
      case InpeSatelliteOverlayMode.off:
        return 'Off';
      case InpeSatelliteOverlayMode.cerradoInpe:
        return 'INPE';
      case InpeSatelliteOverlayMode.brazilMosaic:
        return 'Brasil';
    }
  }

  String get accessibilityLabel {
    switch (this) {
      case InpeSatelliteOverlayMode.off:
        return 'Satélite INPE desativado';
      case InpeSatelliteOverlayMode.cerradoInpe:
        return 'Satélite Cerrado INPE';
      case InpeSatelliteOverlayMode.brazilMosaic:
        return 'Mosaico Brasil INPE trimestral';
    }
  }
}
