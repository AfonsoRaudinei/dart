/// Configuração de runtime via `--dart-define`.
/// SUPABASE_ANON_KEY: use a Publishable key (Project Settings → API Keys).
/// Legacy anon public ainda funciona no mesmo campo.
/// Nunca commitar secrets reais no repositório.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue:
        'https://raw.githubusercontent.com/AfonsoRaudinei/dart/main/docs/legal/politica-de-privacidade.md',
  );

  static const termsOfServiceUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue:
        'https://raw.githubusercontent.com/AfonsoRaudinei/dart/main/docs/legal/termos-de-servico.md',
  );

  static const lgpdContactEmail = String.fromEnvironment(
    'LGPD_CONTACT_EMAIL',
    defaultValue: 'privacidade@soloforte.app',
  );

  static const bundleId = 'com.soloforte.app';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
