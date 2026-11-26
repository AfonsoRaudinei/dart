/// Versão exibida no app (Configurações e menu lateral).
/// Manter em sincronia com `version:` do pubspec.yaml.
const kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.37.0+357',
);
