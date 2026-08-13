/// Links externos oficiais do SoloForte (GitHub Pages).
///
/// Fontes (index.html nos repositórios):
/// - Termos: https://github.com/AfonsoRaudinei/SoloForte-Termos-de-Uso/blob/main/index.html
/// - Privacidade: https://github.com/AfonsoRaudinei/SoloForte-Pol-tica-de-Privacidade/blob/main/index.html
class ExternalLinks {
  ExternalLinks._();

  /// Dashboard admin de feedback (GitHub Pages → lê tabela Supabase `feedback`).
  /// Não é entrada do Side Menu: o usuário abre `/feedback` (FeedbackScreen).
  static const feedbackDashboard =
      'https://afonsoraudinei.github.io/Feedback/';

  /// Termos de Uso (Configurações → Termos de Serviço).
  static const termsOfUse =
      'https://afonsoraudinei.github.io/SoloForte-Termos-de-Uso/';

  /// Política de Privacidade (Configurações → Política de Privacidade).
  static const privacyPolicy =
      'https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/';
}
