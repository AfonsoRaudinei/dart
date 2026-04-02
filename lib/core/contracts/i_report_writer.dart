// lib/core/contracts/i_report_writer.dart
//
// Contrato neutro de geração de relatório de visita.
// ADR-025 (origem — DT-025-7: visit_completion_observer importa
//   generate_relatorio_use_case.dart diretamente)
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// PROIBIDO: expor VisitSessionSnapshot ou qualquer tipo interno de consultoria/.
//
// Substitui a dependência direta em generateRelatorioProvider.

import 'i_occurrence_read.dart';

/// DTO de entrada para geração de relatório de visita.
/// Construído por map/ usando tipos de core/ — sem dependência de consultoria/.
/// Convertido internamente pelo adapter para VisitSessionSnapshot.
/// ADR-025
class VisitReportInput {
  const VisitReportInput({
    required this.sessionId,
    required this.clientId,
    required this.farmName,
    required this.agronomistId,
    required this.startedAt,
    required this.finishedAt,
    this.occurrences = const [],
    this.talhaoId,
    this.talhaoName,
  });

  /// ID da VisitSession original (referência).
  final String sessionId;

  /// ID do cliente/produtor associado à visita.
  final String clientId;

  /// Nome da fazenda visitada.
  /// Proxy para ADR-010 — usar fazendaId como fallback enquanto lookup não existe.
  final String farmName;

  /// ID do agrônomo responsável.
  final String agronomistId;

  /// Data/hora real de início da visita (UTC).
  final DateTime startedAt;

  /// Data/hora real de encerramento da visita (UTC).
  final DateTime finishedAt;

  /// Ocorrências da sessão (via IOccurrenceRead — ADR-024).
  final List<OccurrenceSummary> occurrences;

  /// ID do talhão visitado (opcional).
  final String? talhaoId;

  /// Nome do talhão visitado (opcional — fallback: talhaoId).
  final String? talhaoName;
}

/// Contrato de geração de relatório de visita técnica.
/// Implementado em consultoria/relatorios/infra/report_writer_adapter.dart.
/// Consumidores autorizados: map/ (via visit_completion_observer)
/// ADR-025
abstract interface class IReportWriter {
  /// Gera e persiste o relatório de visita a partir dos dados da sessão.
  /// Operação assíncrona — retorna ID do relatório gerado.
  Future<String> generateReport(VisitReportInput input);
}
