/// Versão exibida no app (Configurações e menu lateral).
/// Manter em sincronia com `version:` do pubspec.yaml.
const kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.36.0+351',
);
