/// Configuração centralizada do ambiente de execução.
///
/// Todas as variáveis são injetadas via `--dart-define` no momento do build.
/// Nunca adicione valores reais neste arquivo — ele é versionado.
///
/// # Como usar em desenvolvimento:
///
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=sua-chave-aqui \
///   --dart-define=ENV=development
/// ```
///
/// # Como usar em CI/CD:
///
/// Passe as variáveis via secrets do GitHub Actions ou equivalente:
/// ```yaml
/// run: flutter build apk --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} ...
/// ```
///
/// # Ambientes disponíveis:
/// - `development` → build local, logs habilitados, mock flags ativo
/// - `staging`     → build de homologação, mock flags desativado
/// - `production`  → build de produção, sem logs, flags reais
class AppConfig {
  AppConfig._();

  // ═══════════════════════════════════════════════════════════════════
  // SUPABASE
  // ═══════════════════════════════════════════════════════════════════

  /// URL do projeto Supabase.
  /// Injetada via --dart-define=SUPABASE_URL=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Chave anônima do Supabase (segura para cliente).
  /// Injetada via --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // ═══════════════════════════════════════════════════════════════════
  // AMBIENTE
  // ═══════════════════════════════════════════════════════════════════

  /// Nome do ambiente de execução.
  /// Valores válidos: development | staging | production
  /// Injetada via --dart-define=ENV=production
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  // ═══════════════════════════════════════════════════════════════════
  // DERIVADOS (computed a partir de `env`)
  // ═══════════════════════════════════════════════════════════════════

  /// Verdadeiro quando rodando em modo de desenvolvimento local.
  static const bool isDevelopment = env == 'development';

  /// Verdadeiro quando rodando em staging.
  static const bool isStaging = env == 'staging';

  /// Verdadeiro quando rodando em produção.
  static const bool isProduction = env == 'production';

  static bool get hasPlaceholderSupabaseUrl =>
      supabaseUrl.isEmpty ||
      supabaseUrl.contains('seu-projeto.supabase.co') ||
      supabaseUrl.contains('example.supabase.co');

  static bool get hasPlaceholderSupabaseAnonKey =>
      supabaseAnonKey.isEmpty ||
      supabaseAnonKey.contains('sua-chave') ||
      supabaseAnonKey.contains('your-anon-key');

  // ═══════════════════════════════════════════════════════════════════
  // VALIDAÇÃO (falha rápida se configuração inválida)
  // ═══════════════════════════════════════════════════════════════════

  /// Valida que as variáveis obrigatórias foram fornecidas.
  ///
  /// Chamado uma única vez no `main()` antes de qualquer inicialização.
  /// Lança [StateError] com mensagem clara se estiver faltando algo.
  static void validate() {
    if (hasPlaceholderSupabaseUrl) {
      throw StateError(
        '[AppConfig] SUPABASE_URL ausente ou placeholder.\n'
        'Configure uma URL real do Supabase via --dart-define=SUPABASE_URL=https://...',
      );
    }
    if (hasPlaceholderSupabaseAnonKey) {
      throw StateError(
        '[AppConfig] SUPABASE_ANON_KEY ausente ou placeholder.\n'
        'Configure uma anon key real via --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
