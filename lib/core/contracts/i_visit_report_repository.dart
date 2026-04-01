// lib/core/contracts/i_visit_report_repository.dart
//
// Contrato neutro — acessível por todos os bounded contexts.
// ADR-024 (origem — DT-023-3: visit_controller depende de SQLiteReportRepository)
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// PROIBIDO: expor ReportType — tipo interno de consultoria/reports/.
// O adapter é responsável por hardcodar ReportType.semanal.

/// DTO com os campos necessários para persistir um relatório de visita.
/// NÃO carrega ReportType (sempre semanal para visitas — hardcode no adapter).
/// NÃO carrega images (não usadas em visitas técnicas).
class VisitReportData {
  const VisitReportData({
    required this.id,
    required this.title,
    required this.clientId,
    required this.startDate,
    required this.endDate,
    required this.content,
    required this.createdAt,
    required this.author,
    this.observations,
  });

  final String id;
  final String title;

  /// ID do produtor associado à visita (clientId no modelo de Report).
  final String clientId;

  final DateTime startDate;
  final DateTime endDate;

  /// Texto completo do relatório gerado automaticamente ao encerrar sessão.
  final String content;

  final DateTime createdAt;
  final String author;
  final String? observations;
}

/// Contrato de persistência de relatório gerado ao encerrar uma sessão de visita.
/// Implementado em consultoria/reports/infra/visit_report_adapter.dart.
/// Consumidores autorizados: visitas/ (via visit_controller)
/// ADR-024
abstract interface class IVisitReportRepository {
  /// Persiste o relatório associado à sessão informada.
  Future<void> saveVisitReport(VisitReportData report, String sessionId);
}
