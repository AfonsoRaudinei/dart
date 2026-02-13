import '../../domain/entities/visit_session.dart';

/// Model para serialização/deserialização de VisitSession
class VisitSessionModel extends VisitSession {
  const VisitSessionModel({
    required super.id,
    required super.eventoId,
    required super.startAtReal,
    super.endAtReal,
    super.duracaoMin,
    super.notasFinais,
    super.checklistSnapshot,
    required super.createdBy,
    required super.createdAt,
    super.syncStatus,
  });

  /// Cria VisitSessionModel a partir de uma entidade VisitSession
  factory VisitSessionModel.fromEntity(VisitSession session) {
    return VisitSessionModel(
      id: session.id,
      eventoId: session.eventoId,
      startAtReal: session.startAtReal,
      endAtReal: session.endAtReal,
      duracaoMin: session.duracaoMin,
      notasFinais: session.notasFinais,
      checklistSnapshot: session.checklistSnapshot,
      createdBy: session.createdBy,
      createdAt: session.createdAt,
      syncStatus: session.syncStatus,
    );
  }

  /// Cria VisitSessionModel a partir de JSON
  factory VisitSessionModel.fromJson(Map<String, dynamic> json) {
    return VisitSessionModel(
      id: json['id'] as String,
      eventoId: json['eventoId'] as String,
      startAtReal: DateTime.parse(json['startAtReal'] as String),
      endAtReal: json['endAtReal'] != null
          ? DateTime.parse(json['endAtReal'] as String)
          : null,
      duracaoMin: json['duracaoMin'] as int?,
      notasFinais: json['notasFinais'] as String?,
      checklistSnapshot: json['checklistSnapshot'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncStatus: json['syncStatus'] as String? ?? 'pending',
    );
  }

  /// Converte VisitSessionModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventoId': eventoId,
      'startAtReal': startAtReal.toIso8601String(),
      'endAtReal': endAtReal?.toIso8601String(),
      'duracaoMin': duracaoMin,
      'notasFinais': notasFinais,
      'checklistSnapshot': checklistSnapshot,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  /// Converte para a entidade de domínio
  VisitSession toEntity() {
    return VisitSession(
      id: id,
      eventoId: eventoId,
      startAtReal: startAtReal,
      endAtReal: endAtReal,
      duracaoMin: duracaoMin,
      notasFinais: notasFinais,
      checklistSnapshot: checklistSnapshot,
      createdBy: createdBy,
      createdAt: createdAt,
      syncStatus: syncStatus,
    );
  }
}
