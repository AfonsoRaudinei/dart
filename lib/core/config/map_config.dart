/// Configurações de estilos de mapa para o aplicativo SoloForte.
///
/// Define diferentes provedores de tiles e estilos de mapa,
/// com foco em design limpo estilo iOS/Apple Maps.
library;

class MapConfig {
  MapConfig._();

  // ═══════════════════════════════════════════════════════════
  // ESTILOS DE MAPA - iOS Style (Clean & Minimal)
  // ═══════════════════════════════════════════════════════════

  /// Carto Voyager - Estilo limpo e moderno (RECOMENDADO para iOS style)
  /// Gratuito até 75k requests/mês
  /// Visual: Clean, cores suaves, tipografia clara
  static const String cartoVoyager =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// Carto Positron - Estilo ultra-minimalista (alternativa clara)
  /// Ideal para dados sobrepostos
  /// Visual: Muito limpo, tons claros, baixo contraste
  static const String cartoPositron =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  /// Stadia Alidade Smooth - Estilo Apple Maps-like
  /// Requer API key (gratuito até 20k tiles/dia)
  /// Visual: Suave, cores pastéis, muito similar ao Apple Maps
  static const String stadiaAlidadeSmooth =
      'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png';

  /// Stadia Alidade Smooth Dark - Versão dark mode
  static const String stadiaAlidadeSmoothDark =
      'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png';

  /// OpenStreetMap - Fallback padrão
  /// Sempre disponível, sem limites
  static const String openStreetMap =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // ═══════════════════════════════════════════════════════════
  // CONFIGURAÇÃO ATIVA
  // ═══════════════════════════════════════════════════════════

  /// Estilo padrão para mapa público (iOS-style)
  /// Carto Voyager: melhor equilíbrio entre estética iOS e disponibilidade
  static const String publicMapDefaultStyle = cartoVoyager;

  /// Fallback se o estilo principal falhar
  static const String fallbackStyle = openStreetMap;

  // ═══════════════════════════════════════════════════════════
  // SUBDOMÍNIOS E CONFIGURAÇÕES
  // ═══════════════════════════════════════════════════════════

  /// Subdomínios para load balancing (Carto suporta a, b, c, d)
  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// User agent para requisições de tiles
  static const String userAgent = 'com.soloforte.app';

  /// Zoom limits
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;
  static const double defaultZoom = 13.0;

  // ═══════════════════════════════════════════════════════════
  // ATRIBUIÇÃO (OBRIGATÓRIO)
  // ═══════════════════════════════════════════════════════════

  /// Atribuição do Carto (obrigatória)
  static const String cartoAttribution = '© OpenStreetMap contributors © CARTO';

  /// Atribuição do OpenStreetMap
  static const String osmAttribution = '© OpenStreetMap contributors';

  /// Atribuição do Stadia Maps
  static const String stadiaAttribution =
      '© Stadia Maps © OpenStreetMap contributors';
}

/// Enum para facilitar seleção de estilos
enum MapStyle {
  /// Estilo iOS-like principal (Carto Voyager)
  iosLight,

  /// Estilo minimalista ultra-clean (Carto Positron)
  iosMinimal,

  /// Estilo Apple Maps replica (Stadia - requer API key)
  iosAppleLike,

  /// Dark mode iOS
  iosDark,

  /// Fallback padrão
  standard,
}

/// Extension para obter URL do estilo
extension MapStyleExtension on MapStyle {
  String get tileUrl {
    switch (this) {
      case MapStyle.iosLight:
        return MapConfig.cartoVoyager;
      case MapStyle.iosMinimal:
        return MapConfig.cartoPositron;
      case MapStyle.iosAppleLike:
        return MapConfig.stadiaAlidadeSmooth;
      case MapStyle.iosDark:
        return MapConfig.stadiaAlidadeSmoothDark;
      case MapStyle.standard:
        return MapConfig.openStreetMap;
    }
  }

  String get attribution {
    switch (this) {
      case MapStyle.iosLight:
      case MapStyle.iosMinimal:
        return MapConfig.cartoAttribution;
      case MapStyle.iosAppleLike:
      case MapStyle.iosDark:
        return MapConfig.stadiaAttribution;
      case MapStyle.standard:
        return MapConfig.osmAttribution;
    }
  }

  List<String>? get subdomains {
    switch (this) {
      case MapStyle.iosLight:
      case MapStyle.iosMinimal:
        return MapConfig.cartoSubdomains;
      default:
        return null;
    }
  }
}
