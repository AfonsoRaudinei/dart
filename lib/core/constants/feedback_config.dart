/// Configuração central do canal de feedback in-app + dashboard GitHub Pages.
class FeedbackConfig {
  FeedbackConfig._();

  static const supportEmail = 'raudyneyb@icloud.com';

  /// Tabela Supabase consumida pelo dashboard:
  /// https://afonsoraudinei.github.io/Feedback/
  static const supabaseTable = 'feedbacks';

  static const notifyFunction = 'notify-feedback';
}
