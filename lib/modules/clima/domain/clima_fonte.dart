/// Fonte dos dados meteorológicos exibidos e compartilhados.
enum ClimaFonte {
  googleWeather,
  openWeather,
  desconhecida,
}

extension ClimaFonteCodec on ClimaFonte {
  String toStorageKey() => switch (this) {
        ClimaFonte.googleWeather => 'google_weather',
        ClimaFonte.openWeather => 'open_weather',
        ClimaFonte.desconhecida => '',
      };

  static ClimaFonte fromStorageKey(String? raw) {
    switch (raw) {
      case 'google_weather':
        return ClimaFonte.googleWeather;
      case 'open_weather':
        return ClimaFonte.openWeather;
      default:
        return ClimaFonte.desconhecida;
    }
  }
}

/// Nome da empresa da API. Vazio quando a fonte não foi gravada.
String climaFonteEmpresa(ClimaFonte fonte) => switch (fonte) {
      ClimaFonte.googleWeather => 'Google Weather',
      ClimaFonte.openWeather => 'OpenWeather',
      ClimaFonte.desconhecida => '',
    };
