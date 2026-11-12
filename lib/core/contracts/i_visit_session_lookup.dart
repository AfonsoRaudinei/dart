// lib/core/contracts/i_visit_session_lookup.dart
//
// Contrato neutro — acessível por todos os bounded contexts.
// ADR-020 (origem) + ADR-023 (expansão — DT-023-1, DT-023-2)
// ADR-060 — listFinished para acerto de visitas sem evento de agenda.
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// RETROCOMPATÍVEL: campos id e status mantidos, novos campos adicionados.

/// DTO mínimo de sessão de visita para consumo por módulos externos.
/// NÃO é espelho completo de VisitSession — apenas campos necessários
/// para contexto de mapa, agenda e consultoria.
class VisitSessionSummary {
  const VisitSessionSummary({
    required this.id,
    required this.producerId,
    required this.status,
    required this.startTime,
    this.farmId,
    this.areaId,
    this.activityType,
    this.endTime,
    this.initialLat,
    this.initialLong,
  });

  final String id;
  final String producerId;
  final String status; // 'active' | 'finished'
  final DateTime startTime;
  final String? farmId;
  final String? areaId;
  final String? activityType;
  final DateTime? endTime;
  final double? initialLat;
  final double? initialLong;

  bool get isActive => status == 'active';
}

/// Contrato de consulta de sessões de visita.
/// Implementado em visitas/infra/visit_session_lookup_adapter.dart
/// Consumidores autorizados: map/, consultoria/, agenda/
/// ADR-023
abstract interface class IVisitSessionLookup {
  /// Retorna a sessão ativa do usuário atual, ou null se não houver.
  Future<VisitSessionSummary?> getActiveSession();

  /// Retorna sessão por ID. Retorna null se não encontrada.
  /// Adicionado em ADR-023 — DT-023-2
  Future<VisitSessionSummary?> findById(String sessionId);

  /// Sessões já encerradas do usuário atual. ADR-060.
  Future<List<VisitSessionSummary>> listFinished();
}
