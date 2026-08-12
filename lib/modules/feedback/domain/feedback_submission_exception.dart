/// Erro de domínio com mensagem segura para exibir na UI.
class FeedbackSubmissionException implements Exception {
  const FeedbackSubmissionException(this.userMessage);

  final String userMessage;

  @override
  String toString() => userMessage;
}
