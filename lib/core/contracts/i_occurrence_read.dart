// lib/core/contracts/i_occurrence_read.dart
//
// Contrato neutro — acessível por todos os bounded contexts.
// ADR-024 (origem — DT-023-3: visit_controller depende de OccurrenceRepository)
// ADR-047 (expansão: campos agronômicos ricos para IReportWriter / HTML)
// ADR-056 (ordem de aplicação: ação, dose, quando)
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// Expõe apenas os campos de Occurrence necessários aos consumidores externos.

/// DTO de ocorrência para consumo por módulos externos.
/// NÃO é espelho completo de Occurrence — campos do relatório de visita.
/// ADR-024 + ADR-025 (lat, lng, fotoPath, registradaEm)
/// ADR-047 (campos ricos nullable)
class OccurrenceSummary {
  const OccurrenceSummary({
    required this.id,
    required this.type,
    required this.description,
    this.lat,
    this.lng,
    this.fotoPath,
    this.registradaEm,
    this.fotoPaths,
    this.categoria,
    this.severity,
    this.geometry,
    this.status,
    this.cultivar,
    this.estadioFenologico,
    this.tipoOcorrencia,
    this.recomendacoes,
    this.recomendacaoAcao,
    this.recomendacaoDose,
    this.recomendacaoQuando,
    this.metricasJson,
    this.nutrientesJson,
    this.categoriasJson,
    this.notasCategoriasJson,
    this.fotosCategoriasJson,
    this.amostraCodigo,
    this.amostraColetor,
    this.amostraTramite,
    this.amostraLaudoTexto,
    this.fieldId,
  });

  final String id;

  /// Categoria/tipo da ocorrência (ex.: 'doenca', 'insetos', 'daninhas').
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

  /// Paths locais adicionais de fotos (opcional).
  final List<String>? fotoPaths;

  /// Categoria agronômica principal (opcional).
  final String? categoria;

  /// Severidade/urgência normalizada (opcional).
  final String? severity;

  /// Geometria GeoJSON original (opcional).
  final String? geometry;

  /// Status operacional (opcional).
  final String? status;

  /// Campos agronômicos ricos (opcional — ADR-047).
  final String? cultivar;
  final String? estadioFenologico;
  final String? tipoOcorrencia;
  final String? recomendacoes;
  final String? recomendacaoAcao;
  final String? recomendacaoDose;
  final String? recomendacaoQuando;
  final String? metricasJson;
  final String? nutrientesJson;
  final String? categoriasJson;
  final String? notasCategoriasJson;
  final String? fotosCategoriasJson;
  final String? amostraCodigo;
  final String? amostraColetor;
  final String? amostraTramite;
  final String? amostraLaudoTexto;

  /// Talhão da ocorrência, quando o relatório foi feito num talhão.
  /// ADR-060 — a agenda mostra "Talhão · Fazenda".
  final String? fieldId;
}

/// Contrato de leitura de ocorrências vinculadas a uma sessão de visita.
/// Implementado em consultoria/occurrences/infra/occurrence_read_adapter.dart.
/// Consumidores autorizados: visitas/ (via visit_controller), map/ (observer)
/// ADR-024 · ADR-047
abstract interface class IOccurrenceRead {
  /// Retorna todas as ocorrências vinculadas à sessão informada.
  /// Retorna lista vazia se não houver ocorrências.
  Future<List<OccurrenceSummary>> getBySessionId(String sessionId);

  /// Ocorrências da sessão visíveis pelos clientes vinculados ao produtor.
  /// ADR-061
  Future<List<OccurrenceSummary>> getAuthorizedBySessionId(
    String sessionId,
    Set<String> authorizedClientIds,
  );
}
