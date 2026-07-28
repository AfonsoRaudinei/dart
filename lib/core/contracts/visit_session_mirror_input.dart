// lib/core/contracts/visit_session_mirror_input.dart
//
// DTO neutro para espelhar agenda_visit_sessions em visit_sessions (ADR-048).
// PROIBIDO: importar lib/modules/ neste arquivo.

/// Entrada para criação de sessão espelhada em `visit_sessions`.
class VisitSessionMirrorInput {
  const VisitSessionMirrorInput({
    required this.id,
    required this.producerId,
    required this.startTime,
    required this.initialLat,
    required this.initialLong,
    required this.userId,
    this.farmId,
    this.areaId,
    this.activityType,
  });

  /// Mesmo UUID de `agenda_visit_sessions.id`.
  final String id;

  /// NOT NULL em `visit_sessions.producer_id` — origem: `event.clienteId`.
  final String producerId;

  final String? farmId;
  final String? areaId;
  final String? activityType;
  final DateTime startTime;
  final double initialLat;
  final double initialLong;

  /// Usuário dono da sessão (`visit_sessions.user_id`).
  final String userId;
}
