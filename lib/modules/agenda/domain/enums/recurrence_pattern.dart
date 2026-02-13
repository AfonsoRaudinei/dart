/// Padrão de recorrência para eventos
enum RecurrencePattern {
  daily,      // Diário
  weekly,     // Semanal
  biweekly,   // Quinzenal
  monthly,    // Mensal
  yearly;     // Anual

  String get label {
    switch (this) {
      case RecurrencePattern.daily:
        return 'Diário';
      case RecurrencePattern.weekly:
        return 'Semanal';
      case RecurrencePattern.biweekly:
        return 'Quinzenal';
      case RecurrencePattern.monthly:
        return 'Mensal';
      case RecurrencePattern.yearly:
        return 'Anual';
    }
  }
}
