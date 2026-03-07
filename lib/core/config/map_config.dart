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

  /// Stadia Stamen Terrain - Estilo natural/verde (PADRÃO mapa privado)
  /// Vegetação verde, água azul, estradas brancas — idêntico ao iOS Fotos/Maps
  /// Gratuito com API key (free tier Stadia Maps)
  /// Paleta de referência: lib/modules/map/presentation/assets/map_style_padrao.json
  static const String stadiaStamenTerrain =
      'https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}.png';

  /// Google Maps Satellite Híbrido — tile endpoint público
  /// lyrs=y = satellite + labels (cidades/rodovias) — recomendado para campo
  /// lyrs=s = satellite puro (sem labels)
  /// Cobertura superior no Brasil rural, zoom até 20+
  /// Subdomínios 0-3 = load balancing automático entre servidores Google
  /// ⚠️ Para produção em escala: ativar billing no Google Cloud Console
  static const String googleSatelliteUrl =
      'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';

  /// Subdomínios do Google Maps Tile Server (load balancing)
  static const List<String> googleSatelliteSubdomains = ['0', '1', '2', '3'];

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
  // STADIA MAPS — API KEY (dart-define injetada no build)
  // ═══════════════════════════════════════════════════════════

  /// Chave da API Stadia Maps — injetada via --dart-define=STADIA_API_KEY=<key>
  /// Free tier: https://client.stadiamaps.com/signup/
  /// Dev sem key: free tier libera requests sem autenticação até threshold diário.
  /// Produção (TestFlight/App Store): OBRIGATÓRIA para evitar bloqueio.
  static const String _stadiaApiKey = String.fromEnvironment(
    'STADIA_API_KEY',
    defaultValue: '',
  );

  /// True se a key foi injetada no build.
  static bool get hasStadiaApiKey => _stadiaApiKey.isNotEmpty;

  /// URL do Stamen Terrain com API key quando disponível.
  /// Sem key → URL base (dev / free tier sem auth).
  /// Com key → appenda ?api_key=<key> (produção).
  static String get stadiaStamenTerrainUrl {
    if (_stadiaApiKey.isNotEmpty) {
      return '$stadiaStamenTerrain?api_key=$_stadiaApiKey';
    }
    return stadiaStamenTerrain;
  }

  // ═══════════════════════════════════════════════════════════
  // SUBDOMÍNIOS E CONFIGURAÇÕES
  // ═══════════════════════════════════════════════════════════

  /// Subdomínios para load balancing (Carto suporta a, b, c, d)
  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// User agent para requisições de tiles.
  /// ⚠️ DEVE bater exatamente com o bundle identifier do build primário.
  /// iOS (TestFlight/App Store): com.soloforte.soloforteApp
  /// Android:                    com.soloforte.soloforte_app
  static const String userAgent = 'com.soloforte.soloforteApp';

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

  /// Atribuição do Google Maps (obrigatória pelos Termos de Serviço)
  static const String googleAttribution = '© Google';
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
