import 'relatorio_status.dart';
import 'visit_session_snapshot.dart';

/// Modelo de domínio: Relatório Técnico de Visita — ADR-009
///
/// Documento estruturado gerado ao finalizar uma VisitSession.
/// Contém o snapshot imutável dos dados de campo coletados durante a visita.
///
/// Ciclo de vida:
///   pendente_revisao → publicado | arquivado
///
/// Persistência: offline-first — SQLite é a fonte da verdade.
///   syncStatus inicial: [RelatorioSyncStatus.local_only]
///
/// REGRA ADR-009: Nenhum import de lib/modules/operacao/ é permitido.
/// A dependência de dados de VisitSession é resolvida via [VisitSessionSnapshot].
class RelatorioTecnico {
  // ── Campos obrigatórios ──────────────────────────────────────────────

  /// Identificador único (UUID v4).
  final String id;

  /// Referência à VisitSession original (UUID — NÃO importa a entidade).
  final String visitSessionId;

  /// ID do cliente associado.
  final String clientId;

  /// ID do agrônomo responsável.
  final String agronomistId;

  /// Nome da fazenda visitada.
  final String farmName;

  /// Início do período da visita (UTC).
  final DateTime periodStart;

  /// Fim do período da visita (UTC).
  final DateTime periodEnd;

  /// Status do relatório no ciclo de vida.
  final RelatorioStatus status;

  /// Status de sincronização offline-first.
  final RelatorioSyncStatus syncStatus;

  /// Timestamp de criação (UTC).
  final DateTime createdAt;

  /// Timestamp da última atualização (UTC).
  final DateTime updatedAt;

  // ── Campos opcionais ─────────────────────────────────────────────────

  /// Soft delete: preenchido ao excluir logicamente. NUNCA deletar fisicamente.
  final DateTime? deletedAt;

  /// Título editável pelo agrônomo (opcional).
  final String? title;

  /// Seção de notas livres editável pelo agrônomo (opcional).
  final String? customNotes;

  /// UUIDs das [PublicacaoTecnica] incluídas como referência neste relatório.
  final List<String> publicacoesRefs;

  /// Snapshot imutável das ocorrências registradas na sessão.
  final List<OcorrenciaSnapshot> ocorrencias;

  /// Talhões visitados na sessão.
  final List<TalhaoVisitado> talhoes;

  /// Paths locais das fotos registradas.
  final List<String> fotos;

  /// Dados de monitoramento coletados na sessão.
  final List<MonitoramentoSnapshot> monitoramentos;

  const RelatorioTecnico({
    required this.id,
    required this.visitSessionId,
    required this.clientId,
    required this.agronomistId,
    required this.farmName,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.title,
    this.customNotes,
    this.publicacoesRefs = const [],
    this.ocorrencias = const [],
    this.talhoes = const [],
    this.fotos = const [],
    this.monitoramentos = const [],
  });

  // ── Factory ──────────────────────────────────────────────────────────

  /// Cria um [RelatorioTecnico] a partir de um [VisitSessionSnapshot].
  ///
  /// Valores padrão:
  ///   - [status] = [RelatorioStatus.pendente_revisao]
  ///   - [syncStatus] = [RelatorioSyncStatus.local_only]
  factory RelatorioTecnico.fromSnapshot({
    required String id,
    required String agronomistId,
    required VisitSessionSnapshot snapshot,
    required DateTime now,
  }) {
    return RelatorioTecnico(
      id: id,
      visitSessionId: snapshot.sessionId,
      clientId: snapshot.clientId,
      agronomistId: agronomistId,
      farmName: snapshot.farmName,
      periodStart: snapshot.startedAt,
      periodEnd: snapshot.finishedAt,
      status: RelatorioStatus.pendente_revisao,
      syncStatus: RelatorioSyncStatus.local_only,
      createdAt: now,
      updatedAt: now,
      ocorrencias: snapshot.ocorrencias,
      talhoes: snapshot.talhoes,
      fotos: snapshot.fotos,
      monitoramentos: snapshot.monitoramentos,
    );
  }

  // ── copyWith ─────────────────────────────────────────────────────────

  RelatorioTecnico copyWith({
    String? id,
    String? visitSessionId,
    String? clientId,
    String? agronomistId,
    String? farmName,
    DateTime? periodStart,
    DateTime? periodEnd,
    RelatorioStatus? status,
    RelatorioSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? title,
    String? customNotes,
    List<String>? publicacoesRefs,
    List<OcorrenciaSnapshot>? ocorrencias,
    List<TalhaoVisitado>? talhoes,
    List<String>? fotos,
    List<MonitoramentoSnapshot>? monitoramentos,
  }) {
    return RelatorioTecnico(
      id: id ?? this.id,
      visitSessionId: visitSessionId ?? this.visitSessionId,
      clientId: clientId ?? this.clientId,
      agronomistId: agronomistId ?? this.agronomistId,
      farmName: farmName ?? this.farmName,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      customNotes: customNotes ?? this.customNotes,
      publicacoesRefs: publicacoesRefs ?? this.publicacoesRefs,
      ocorrencias: ocorrencias ?? this.ocorrencias,
      talhoes: talhoes ?? this.talhoes,
      fotos: fotos ?? this.fotos,
      monitoramentos: monitoramentos ?? this.monitoramentos,
    );
  }

  // ── Serialização ─────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'visitSessionId': visitSessionId,
    'clientId': clientId,
    'agronomistId': agronomistId,
    'farmName': farmName,
    'periodStart': periodStart.toUtc().toIso8601String(),
    'periodEnd': periodEnd.toUtc().toIso8601String(),
    'status': status.toJson(),
    'syncStatus': syncStatus.toJson(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'title': title,
    'customNotes': customNotes,
    'publicacoesRefs': publicacoesRefs,
    'ocorrencias': ocorrencias.map((e) => e.toJson()).toList(),
    'talhoes': talhoes.map((e) => e.toJson()).toList(),
    'fotos': fotos,
    'monitoramentos': monitoramentos.map((e) => e.toJson()).toList(),
  };

  factory RelatorioTecnico.fromJson(Map<String, dynamic> json) {
    return RelatorioTecnico(
      id: json['id'] as String,
      visitSessionId: json['visitSessionId'] as String,
      clientId: json['clientId'] as String,
      agronomistId: json['agronomistId'] as String,
      farmName: json['farmName'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String).toUtc(),
      periodEnd: DateTime.parse(json['periodEnd'] as String).toUtc(),
      status: RelatorioStatus.fromJson(json['status'] as String),
      syncStatus: RelatorioSyncStatus.fromJson(json['syncStatus'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String).toUtc()
          : null,
      title: json['title'] as String?,
      customNotes: json['customNotes'] as String?,
      publicacoesRefs:
          (json['publicacoesRefs'] as List<dynamic>?)?.cast<String>() ?? [],
      ocorrencias:
          (json['ocorrencias'] as List<dynamic>?)
              ?.map(
                (e) => OcorrenciaSnapshot.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      talhoes:
          (json['talhoes'] as List<dynamic>?)
              ?.map((e) => TalhaoVisitado.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fotos: (json['fotos'] as List<dynamic>?)?.cast<String>() ?? [],
      monitoramentos:
          (json['monitoramentos'] as List<dynamic>?)
              ?.map(
                (e) =>
                    MonitoramentoSnapshot.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
