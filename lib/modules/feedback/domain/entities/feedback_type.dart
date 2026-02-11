enum FeedbackType {
  bug,
  suggestion,
  praise;

  String get label {
    switch (this) {
      case FeedbackType.bug:
        return 'Bug';
      case FeedbackType.suggestion:
        return 'Sugestão';
      case FeedbackType.praise:
        return 'Elogios';
    }
  }
}
