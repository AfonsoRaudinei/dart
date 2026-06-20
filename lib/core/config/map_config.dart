/// Configurações de estilos de mapa para o aplicativo SoloForte.
///
/// Define diferentes provedores de tiles e estilos de mapa,
/// com foco em design limpo estilo iOS/Apple Maps.
library;

import '../domain/map_models.dart';

class MapLayerTileConfig {
  final String urlTemplate;
  final String attribution;
  final List<String> subdomains;
  final double maxZoom;
  final int maxNativeZoom;
  final bool retinaMode;
  final String? fallbackUrl;
  final bool requiresApiKey;
  final bool isFallback;

  const MapLayerTileConfig({
    required this.urlTemplate,
    required this.attribution,
    this.subdomains = const [],
    required this.maxZoom,
    required this.maxNativeZoom,
    this.retinaMode = false,
    this.fallbackUrl,
    this.requiresApiKey = false,
    this.isFallback = false,
  });
}

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

  /// Google Maps Satellite — tile endpoint público.
  /// lyrs=s = satellite puro (sem labels), melhor para desenho/medição.
  /// Evita textos no mapa e reduz poluição visual sobre polígonos.
  ///
  /// Observação: alguns servidores devolvem uma imagem "Zoom Level Not
  /// Supported" em zooms nativos altos. Por isso o app limita o zoom nativo
  /// abaixo e deixa o FlutterMap fazer overzoom visual.
  /// Subdomínios 0-3 = load balancing automático entre servidores Google
  static const String googleSatelliteUrl =
      'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';

  /// Subdomínios do Google Maps Tile Server (load balancing)
  static const List<String> googleSatelliteSubdomains = ['0', '1', '2', '3'];

  /// Esri World Imagery — mantido apenas como referência/compatibilidade.
  ///
  /// Não usar como fallback automático no mapa principal: em algumas regiões ou
  /// níveis de zoom o serviço devolve um tile válido com o texto "Zoom Level
  /// Not Supported", que polui visualmente o mapa e não dispara erro HTTP.
  static const String esriWorldImagery =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  /// Esri World Topographic — mantido apenas como referência/compatibilidade.
  ///
  /// Pelo mesmo motivo de [esriWorldImagery], não deve ser fallback automático
  /// das camadas base em produção.
  static const String esriWorldTopo =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';

  /// MapTiler Satellite — imagem satelital limpa, sem labels.
  /// Cobertura global oficial e estável para uso agrícola/desenho.
  /// Requer API key via --dart-define=MAPTILER_API_KEY=[key]
  /// Free tier: 100k requests/mês — https://www.maptiler.com/cloud/
  static String mapTilerSatelliteUrl(String apiKey) =>
      'https://api.maptiler.com/maps/satellite-v4/256/{z}/{x}/{y}.jpg?key=$apiKey';

  /// MapTiler Hybrid — imagem satelital com labels.
  /// Mantido para cenários futuros onde nomes/rodovias sejam necessários.
  /// Requer API key via --dart-define=MAPTILER_API_KEY=[key]
  /// Free tier: 100k requests/mês — https://www.maptiler.com/cloud/
  static String mapTilerHybridUrl(String apiKey) =>
      'https://api.maptiler.com/maps/hybrid/256/{z}/{x}/{y}{r}.jpg?key=$apiKey';

  /// MapTiler Landscape — Estilo natural com relevo suave.
  /// Visual mais vivo, próximo do Apple Maps: verdes, água azul e estradas limpas.
  /// Requer API key via --dart-define=MAPTILER_API_KEY=[key]
  /// Free tier: 100k requests/mês — https://www.maptiler.com/cloud/
  /// maxZoom: 18 (mesmo do Google Satellite)
  static String mapTilerLandscapeUrl(String apiKey) =>
      'https://api.maptiler.com/maps/landscape/256/{z}/{x}/{y}{r}.png?key=$apiKey';

  /// MapTiler Outdoor — Estilo topográfico técnico com trilhas/curvas de nível.
  /// Visual: verde intenso, lagos azuis, rodovias limpas — similar ao Apple Maps terrain
  /// Ideal para uso agrícola/campo: mostra relevo, vegetação e hidrografia
  /// Requer API key via --dart-define=MAPTILER_API_KEY=[key]
  /// Free tier: 100k requests/mês
  static String mapTilerOutdoorUrl(String apiKey) =>
      'https://api.maptiler.com/maps/outdoor-v2/256/{z}/{x}/{y}{r}.png?key=$apiKey';

  /// OpenStreetMap - Fallback padrão
  /// Sempre disponível, sem limites
  static const String openStreetMap =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Carto Voyager com placeholder retina para fallback visual em telas densas.
  static const String cartoVoyagerRetina =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

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

  /// Chave da API Stadia Maps — injetada via --dart-define=STADIA_API_KEY=[key]
  /// Free tier: https://client.stadiamaps.com/signup/
  /// Dev sem key: free tier libera requests sem autenticação até threshold diário.
  /// Produção (TestFlight/App Store): OBRIGATÓRIA para evitar bloqueio.
  static const String _stadiaApiKey = String.fromEnvironment(
    'STADIA_API_KEY',
    defaultValue: '',
  );

  /// True se a key foi injetada no build.
  static bool get hasStadiaApiKey => _stadiaApiKey.isNotEmpty;

  /// True se a key MapTiler foi injetada no build.
  static bool hasMapTilerApiKey(String apiKey) => apiKey.isNotEmpty;

  /// URL do Stamen Terrain com API key quando disponível.
  /// Sem key → fallback OpenStreetMap Carto (gratuito, sem auth).
  /// Com key → Stadia Stamen Terrain com ?api_key=[key] (produção).
  static String get stadiaStamenTerrainUrl {
    if (_stadiaApiKey.isNotEmpty) {
      return '$stadiaStamenTerrain?api_key=$_stadiaApiKey';
    }
    // Fallback gratuito quando STADIA_API_KEY não configurada (dev/CI).
    // OSM Carto não requer autenticação e evita HTTP 403.
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
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

  static const double satelliteMaxZoom = 22.0;
  static const int satelliteMaxNativeZoom = 18;
  static const int mapTilerSatelliteMaxNativeZoom = 20;
  static const double defaultLayerMaxZoom = 18.0;
  static const int defaultLayerMaxNativeZoom = 18;
  static const double mapTilerStyledMaxZoom = 22.0;
  static const int mapTilerStyledMaxNativeZoom = 22;

  static MapLayerTileConfig tileConfigForLayer(
    LayerType type, {
    required String mapTilerApiKey,
  }) {
    switch (type) {
      case LayerType.satellite:
        if (hasMapTilerApiKey(mapTilerApiKey)) {
          return MapLayerTileConfig(
            urlTemplate: mapTilerSatelliteUrl(mapTilerApiKey),
            attribution: mapTilerAttribution,
            maxZoom: satelliteMaxZoom,
            maxNativeZoom: mapTilerSatelliteMaxNativeZoom,
            requiresApiKey: true,
          );
        }
        return const MapLayerTileConfig(
          urlTemplate: googleSatelliteUrl,
          attribution: googleAttribution,
          subdomains: googleSatelliteSubdomains,
          maxZoom: satelliteMaxZoom,
          maxNativeZoom: satelliteMaxNativeZoom,
        );
      case LayerType.relevo:
        if (!hasMapTilerApiKey(mapTilerApiKey)) {
          if (hasStadiaApiKey) {
            return MapLayerTileConfig(
              urlTemplate: stadiaStamenTerrainUrl,
              attribution: stadiaAttribution,
              maxZoom: defaultLayerMaxZoom,
              maxNativeZoom: defaultLayerMaxNativeZoom,
              isFallback: true,
            );
          }
          return const MapLayerTileConfig(
            urlTemplate: cartoVoyagerRetina,
            attribution: cartoAttribution,
            subdomains: cartoSubdomains,
            maxZoom: defaultLayerMaxZoom,
            maxNativeZoom: defaultLayerMaxNativeZoom,
            retinaMode: true,
            isFallback: true,
          );
        }
        return MapLayerTileConfig(
          urlTemplate: mapTilerLandscapeUrl(mapTilerApiKey),
          attribution: mapTilerAttribution,
          maxZoom: mapTilerStyledMaxZoom,
          maxNativeZoom: mapTilerStyledMaxNativeZoom,
          retinaMode: true,
          requiresApiKey: true,
        );
      case LayerType.standard:
        if (hasMapTilerApiKey(mapTilerApiKey)) {
          return MapLayerTileConfig(
            urlTemplate: mapTilerLandscapeUrl(mapTilerApiKey),
            attribution: mapTilerAttribution,
            maxZoom: mapTilerStyledMaxZoom,
            maxNativeZoom: mapTilerStyledMaxNativeZoom,
            retinaMode: true,
            requiresApiKey: true,
          );
        }
        return const MapLayerTileConfig(
          urlTemplate: cartoVoyagerRetina,
          attribution: cartoAttribution,
          subdomains: cartoSubdomains,
          maxZoom: defaultLayerMaxZoom,
          maxNativeZoom: defaultLayerMaxNativeZoom,
          retinaMode: true,
        );
    }
  }

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

  /// Atribuição da Esri (obrigatória)
  static const String esriAttribution = '© Esri';

  /// Atribuição do MapTiler (obrigatória pelos Termos de Serviço)
  static const String mapTilerAttribution =
      '© MapTiler © OpenStreetMap contributors';

  // ═══════════════════════════════════════════════════════════
  // RAINVIEWER — Radar de Precipitação (ADR-028)
  // ═══════════════════════════════════════════════════════════

  /// URL do manifesto JSON da RainViewer (lista de timestamps disponíveis).
  /// Retorna: radar.past[].{time, path}
  /// Sem autenticação — gratuito para tiles básicos.
  static const String rainViewerApiUrl =
      'https://api.rainviewer.com/public/weather-maps.json';

  /// Base dos tiles de radar RainViewer.
  /// Template completo: '$rainViewerTileBase{path}/512/{z}/{x}/{y}/2/1_1.png'
  /// {path} = valor de radar.past.last.path do manifesto JSON.
  static const String rainViewerTileBase = 'https://tilecache.rainviewer.com';

  /// Opacidade do overlay de radar (0.0–1.0).
  /// 0.75 = eco de chuva nítido sobre o satélite, mantendo o mapa base legível.
  static const double radarOverlayOpacity = 0.75;

  /// Zoom máximo nativo confiável para tiles RainViewer.
  static const int rainViewerMaxNativeZoom = 10;

  /// Zoom máximo visual do overlay; acima do nativo o FlutterMap faz overzoom.
  static const double rainViewerMaxZoom = satelliteMaxZoom;

  /// Intervalo entre frames da animação do radar RainViewer.
  static const Duration rainViewerAnimationFrameInterval = Duration(
    milliseconds: 700,
  );
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
