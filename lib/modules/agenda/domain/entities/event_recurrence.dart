import '../enums/recurrence_pattern.dart';

/// Configuração de recorrência para eventos
class EventRecurrence {
  final RecurrencePattern pattern;
  final int interval; // Ex: a cada 2 semanas
  final DateTime? endDate; // Até quando repetir
  final int? occurrences; // Quantidade de ocorrências

  const EventRecurrence({
    required this.pattern,
    this.interval = 1,
    this.endDate,
    this.occurrences,
  });

  /// Calcula próxima data baseado no padrão
  DateTime getNextDate(DateTime currentDate) {
    switch (pattern) {
      case RecurrencePattern.daily:
        return currentDate.add(Duration(days: interval));
      
      case RecurrencePattern.weekly:
        return currentDate.add(Duration(days: 7 * interval));
      
      case RecurrencePattern.biweekly:
        return currentDate.add(Duration(days: 14 * interval));
      
      case RecurrencePattern.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + interval,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
      
      case RecurrencePattern.yearly:
        return DateTime(
          currentDate.year + interval,
          currentDate.month,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
    }
  }

  /// Verifica se deve continuar gerando
  bool shouldContinue(DateTime currentDate, int count) {
    if (endDate != null && currentDate.isAfter(endDate!)) {
      return false;
    }
    
    if (occurrences != null && count >= occurrences!) {
      return false;
    }
    
    return true;
  }

  EventRecurrence copyWith({
    RecurrencePattern? pattern,
    int? interval,
    DateTime? endDate,
    int? occurrences,
    bool clearEndDate = false,
    bool clearOccurrences = false,
  }) {
    return EventRecurrence(
      pattern: pattern ?? this.pattern,
      interval: interval ?? this.interval,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      occurrences: clearOccurrences ? null : (occurrences ?? this.occurrences),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern.name,
      'interval': interval,
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }

  factory EventRecurrence.fromJson(Map<String, dynamic> json) {
    return EventRecurrence(
      pattern: RecurrencePattern.values.byName(json['pattern'] as String),
      interval: json['interval'] as int? ?? 1,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      occurrences: json['occurrences'] as int?,
    );
  }
}
