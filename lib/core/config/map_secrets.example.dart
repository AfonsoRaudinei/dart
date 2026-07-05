/// Template local opcional — copie para `map_secrets.dart` se quiser override manual.
///
/// O projeto usa preferencialmente `--dart-define=MAPTILER_API_KEY=...`
/// via [MapConfig.kMapTilerApiKey] em `map_config.dart`.
///
/// Este arquivo NÃO é importado pelo app. Serve apenas como referência.
library;

const String kMapTilerApiKey = String.fromEnvironment(
  'MAPTILER_API_KEY',
  defaultValue: '',
);
