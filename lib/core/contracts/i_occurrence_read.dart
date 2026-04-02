// lib/core/contracts/i_occurrence_read.dart
//
// Contrato neutro — acessível por todos os bounded contexts.
// ADR-024 (origem — DT-023-3: visit_controller depende de OccurrenceRepository)
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// Expõe apenas os 3 campos de Occurrence necessários ao visit_controller.

/// DTO mínimo de ocorrência para consumo por módulos externos.
/// NÃO é espelho completo de Occurrence — apenas os campos necessários
/// para compor o relatório de visita.
/// ADR-024 + ADR-025 (expansão: lat, lng, fotoPath, registradaEm)
class OccurrenceSummary {
  const OccurrenceSummary({
    required this.id,
    required this.type,
    required this.description,
    this.lat,
    this.lng,
    this.fotoPath,
    this.registradaEm,
  });

  final String id;

  /// Categoria da ocorrência (ex.: 'doenca', 'insetos', 'daninhas').
  final String type;

  /// Descrição livre registrada pelo técnico no campo.
  final String description;

  /// Latitude do ponto de ocorrência (opcional).
  final double? lat;

  /// Longitude do ponto de ocorrência (opcional).
  final double? lng;

  /// Path local da foto vinculada (opcional).
  final String? fotoPath;

  /// Data/hora em que a ocorrência foi registrada (UTC).
  final DateTime? registradaEm;
}

/// Contrato de leitura de ocorrências vinculadas a uma sessão de visita.
/// Implementado em consultoria/occurrences/infra/occurrence_read_adapter.dart.
/// Consumidores autorizados: visitas/ (via visit_controller)
/// ADR-024
abstract interface class IOccurrenceRead {
  /// Retorna todas as ocorrências vinculadas à sessão informada.
  /// Retorna lista vazia se não houver ocorrências.
  Future<List<OccurrenceSummary>> getBySessionId(String sessionId);
}
