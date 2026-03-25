/// Configuração das APIs meteorológicas do módulo Clima.
///
/// Chaves injetadas via --dart-define no momento do build.
/// NUNCA adicione valores reais neste arquivo — ele é versionado.
///
/// # Desenvolvimento:
/// ```bash
/// flutter run \
///   --dart-define=OPENWEATHER_API_KEY=<sua_chave_openweather> \
///   --dart-define=EMBRAPA_CLIMA_API_KEY=<sua_chave_embrapa>
/// ```
abstract final class ClimaConfig {
  // ═══════════════════════════════════════════════════════════════════
  // OPENWEATHERMAP
  // ═══════════════════════════════════════════════════════════════════

  /// Chave da API OpenWeatherMap.
  /// Injetada via --dart-define=OPENWEATHER_API_KEY=...
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '',
  );

  /// Base URL da API One Call 3.0 (atual/horária/semanal/alertas em 1 request).
  static const String openWeatherBaseUrl =
      'https://api.openweathermap.org/data/3.0/onecall';

  // ═══════════════════════════════════════════════════════════════════
  // EMBRAPA AGROMETEOROLOGIA
  // ═══════════════════════════════════════════════════════════════════

  /// Chave da API Embrapa Agrometeorologia.
  /// Injetada via --dart-define=EMBRAPA_CLIMA_API_KEY=...
  static const String embrapaApiKey = String.fromEnvironment(
    'EMBRAPA_CLIMA_API_KEY',
    defaultValue: '',
  );

  /// Base URL Embrapa (endpoint de previsão agrometeorológica).
  static const String embrapaBaseUrl =
      'https://api.cnptia.embrapa.br/satveg/v2';

  // ═══════════════════════════════════════════════════════════════════
  // TTL DE CACHE
  // ═══════════════════════════════════════════════════════════════════

  /// Tempo de vida do cache local (15 minutos).
  static const Duration cacheTtl = Duration(minutes: 15);
}
