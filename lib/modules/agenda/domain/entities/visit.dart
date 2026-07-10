import 'dart:math' as math;

import '../entities/event.dart';
import '../enums/event_status.dart';
import 'package:flutter/material.dart';

/// Visit é um alias para Event
///
/// Usamos Event como entidade única que representa tanto:
/// - Planejamento (agenda)
/// - Execução (sessão de visita)
/// - Conclusão
///
/// Não criar entidade separada. Event é a fonte única da verdade.
typedef Visit = Event;

/// Extensões para facilitar o uso de Event como Visit
extension VisitExtension on Event {
  /// Status de visita (mapeamento semântico)
  VisitStatus get visitStatus {
    switch (status) {
      case EventStatus.agendado:
        return VisitStatus.planejada;
      case EventStatus.emAndamento:
        return VisitStatus.emAndamento;
      case EventStatus.concluido:
        return VisitStatus.concluida;
      case EventStatus.cancelado:
        return VisitStatus.cancelada;
      case EventStatus.finalizando:
        return VisitStatus.emAndamento; // Ainda em andamento
    }
  }

  /// Verifica se a visita está planejada
  bool get isPlanejada => status == EventStatus.agendado;

  /// Verifica se a visita está em andamento
  bool get isEmAndamento =>
      status == EventStatus.emAndamento || status == EventStatus.finalizando;

  /// Verifica se a visita foi concluída
  bool get isConcluida => status == EventStatus.concluido;

  /// Verifica se a visita foi cancelada
  bool get isCancelada => status == EventStatus.cancelado;

  /// Verifica se pode iniciar a visita
  bool get canStart => status == EventStatus.agendado && visitSessionId == null;

  /// Verifica se pode encerrar a visita
  bool get canFinish =>
      (status == EventStatus.emAndamento ||
          status == EventStatus.finalizando) &&
      visitSessionId != null;

  /// Retorna a cor representativa do status
  int get statusColor {
    switch (visitStatus) {
      case VisitStatus.planejada:
        return 0xFF007AFF; // Azul
      case VisitStatus.emAndamento:
        return 0xFFFBBF24; // Laranja
      case VisitStatus.concluida:
        return 0xFF4ADE80; // Verde
      case VisitStatus.cancelada:
        return 0xFFDC2626; // Vermelho
    }
  }

  /// Retorna o ícone representativo do status
  String get statusIcon {
    switch (visitStatus) {
      case VisitStatus.planejada:
        return '📅';
      case VisitStatus.emAndamento:
        return '🔄';
      case VisitStatus.concluida:
        return '✅';
      case VisitStatus.cancelada:
        return '❌';
    }
  }

  /// Verifica se a visita tem horário definido
  bool get hasScheduledTime => startTime != null && endTime != null;

  /// Retorna o horário formatado (HH:mm - HH:mm)
  String get formattedTimeRange {
    if (!hasScheduledTime) return '';
    return '${_formatTime(startTime!)} - ${_formatTime(endTime!)}';
  }

  /// Formata TimeOfDay para string
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Verifica se há conflito de horário com outra visita
  bool hasTimeConflictWith(Event other) {
    // Se alguma das visitas não tem horário definido, não há conflito
    if (!hasScheduledTime || other.startTime == null || other.endTime == null) {
      return false;
    }

    // Se as datas são diferentes, não há conflito
    if (!_isSameDay(dataInicioPlanejada, other.dataInicioPlanejada)) {
      return false;
    }

    // Verifica sobreposição de horários
    final thisStartMinutes = startTime!.hour * 60 + startTime!.minute;
    final thisEndMinutes = endTime!.hour * 60 + endTime!.minute;
    final otherStartMinutes =
        other.startTime!.hour * 60 + other.startTime!.minute;
    final otherEndMinutes = other.endTime!.hour * 60 + other.endTime!.minute;

    return thisStartMinutes < otherEndMinutes &&
        thisEndMinutes > otherStartMinutes;
  }

  /// Verifica se duas datas são do mesmo dia
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Retorna a cor da borda baseada na prioridade
  Color get priorityBorderColor {
    return priority.color;
  }

  /// Retorna a espessura da borda baseada na prioridade
  double get priorityBorderWidth {
    switch (priority) {
      case VisitPriority.baixa:
        return 1.0;
      case VisitPriority.normal:
        return 2.0;
      case VisitPriority.alta:
        return 3.0;
    }
  }

  /// Verifica se a visita tem localização definida
  bool get hasLocation => latitude != null && longitude != null;

  /// Calcula a distância em km para outra visita usando fórmula Haversine
  double? distanceToInKm(Event other) {
    // Se alguma das visitas não tem localização, retorna null
    if (!hasLocation || other.latitude == null || other.longitude == null) {
      return null;
    }

    return _haversineDistance(
      latitude!,
      longitude!,
      other.latitude!,
      other.longitude!,
    );
  }

  /// Calcula distância entre dois pontos geográficos usando fórmula Haversine
  /// Retorna distância em quilômetros
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final lat1Rad = _degreesToRadians(lat1);
    final lon1Rad = _degreesToRadians(lon1);
    final lat2Rad = _degreesToRadians(lat2);
    final lon2Rad = _degreesToRadians(lon2);
    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Converte graus para radianos
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Verifica se há possível conflito logístico com outra visita
  /// Retorna true se distância > 50km E intervalo < 1h
  bool hasLogisticalConflictWith(Event other) {
    // Se não é o mesmo dia, não há conflito
    if (!_isSameDay(dataInicioPlanejada, other.dataInicioPlanejada)) {
      return false;
    }

    // Se não tem localização ou horário, não pode calcular
    if (!hasLocation || !hasScheduledTime) {
      return false;
    }
    if (other.latitude == null ||
        other.longitude == null ||
        other.startTime == null ||
        other.endTime == null) {
      return false;
    }

    // Calcula distância
    final distance = distanceToInKm(other);
    if (distance == null || distance <= 50.0) {
      return false;
    }

    // Calcula intervalo de tempo entre as visitas
    final thisEndMinutes = endTime!.hour * 60 + endTime!.minute;
    final otherStartMinutes =
        other.startTime!.hour * 60 + other.startTime!.minute;

    // Se this termina antes de other começar
    if (thisEndMinutes <= otherStartMinutes) {
      final intervalMinutes = otherStartMinutes - thisEndMinutes;
      return intervalMinutes < 60; // Menos de 1 hora
    }

    // Se other termina antes de this começar
    final otherEndMinutes = other.endTime!.hour * 60 + other.endTime!.minute;
    final thisStartMinutes = startTime!.hour * 60 + startTime!.minute;
    if (otherEndMinutes <= thisStartMinutes) {
      final intervalMinutes = thisStartMinutes - otherEndMinutes;
      return intervalMinutes < 60; // Menos de 1 hora
    }

    return false;
  }
}

/// Status simplificado de visita
enum VisitStatus {
  /// Visita planejada, ainda não iniciada
  planejada,

  /// Visita em andamento
  emAndamento,

  /// Visita concluída
  concluida,

  /// Visita cancelada
  cancelada,
}

extension VisitStatusExtension on VisitStatus {
  String get label {
    switch (this) {
      case VisitStatus.planejada:
        return 'Planejada';
      case VisitStatus.emAndamento:
        return 'Em Andamento';
      case VisitStatus.concluida:
        return 'Concluída';
      case VisitStatus.cancelada:
        return 'Cancelada';
    }
  }
}

/// Prioridade de visita
enum VisitPriority {
  baixa,
  normal,
  alta;

  String get label {
    switch (this) {
      case VisitPriority.baixa:
        return 'Baixa';
      case VisitPriority.normal:
        return 'Normal';
      case VisitPriority.alta:
        return 'Alta';
    }
  }

  Color get color {
    switch (this) {
      case VisitPriority.baixa:
        return const Color(0xFF9CA3AF); // Cinza
      case VisitPriority.normal:
        return const Color(0xFF3B82F6); // Azul
      case VisitPriority.alta:
        return const Color(0xFFEF4444); // Vermelho
    }
  }

  String toValue() {
    switch (this) {
      case VisitPriority.baixa:
        return 'baixa';
      case VisitPriority.normal:
        return 'normal';
      case VisitPriority.alta:
        return 'alta';
    }
  }

  static VisitPriority fromString(String value) {
    switch (value) {
      case 'baixa':
        return VisitPriority.baixa;
      case 'alta':
        return VisitPriority.alta;
      default:
        return VisitPriority.normal;
    }
  }
}
