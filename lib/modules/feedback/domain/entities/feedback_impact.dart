enum FeedbackImpact {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case FeedbackImpact.low:
        return 'Baixo';
      case FeedbackImpact.medium:
        return 'Médio';
      case FeedbackImpact.high:
        return 'Alto';
      case FeedbackImpact.critical:
        return 'Crítico';
    }
  }

  String get storageValue => name;

  static FeedbackImpact fromStorageValue(String? value) {
    switch (value) {
      case 'low':
        return FeedbackImpact.low;
      case 'medium':
        return FeedbackImpact.medium;
      case 'high':
        return FeedbackImpact.high;
      case 'critical':
        return FeedbackImpact.critical;
      default:
        return FeedbackImpact.medium;
    }
  }
}
