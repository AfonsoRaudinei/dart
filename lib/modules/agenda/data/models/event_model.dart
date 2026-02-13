import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';
import '../../domain/enums/event_type.dart';

/// Model para serialização/deserialização de Event
class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.tipo,
    required super.clienteId,
    super.fazendaId,
    super.talhaoId,
    required super.titulo,
    required super.dataInicioPlanejada,
    required super.dataFimPlanejada,
    required super.status,
    super.visitSessionId,
    super.serieId,
    required super.createdAt,
    required super.updatedAt,
    super.syncStatus,
  });

  /// Cria EventModel a partir de uma entidade Event
  factory EventModel.fromEntity(Event event) {
    return EventModel(
      id: event.id,
      tipo: event.tipo,
      clienteId: event.clienteId,
      fazendaId: event.fazendaId,
      talhaoId: event.talhaoId,
      titulo: event.titulo,
      dataInicioPlanejada: event.dataInicioPlanejada,
      dataFimPlanejada: event.dataFimPlanejada,
      status: event.status,
      visitSessionId: event.visitSessionId,
      serieId: event.serieId,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      syncStatus: event.syncStatus,
    );
  }

  /// Cria EventModel a partir de JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      tipo: EventType.values.byName(json['tipo'] as String),
      clienteId: json['clienteId'] as String,
      fazendaId: json['fazendaId'] as String?,
      talhaoId: json['talhaoId'] as String?,
      titulo: json['titulo'] as String,
      dataInicioPlanejada: DateTime.parse(json['dataInicioPlanejada'] as String),
      dataFimPlanejada: DateTime.parse(json['dataFimPlanejada'] as String),
      status: EventStatus.values.byName(json['status'] as String),
      visitSessionId: json['visitSessionId'] as String?,
      serieId: json['serieId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: json['syncStatus'] as String? ?? 'pending',
    );
  }

  /// Converte EventModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.name,
      'clienteId': clienteId,
      'fazendaId': fazendaId,
      'talhaoId': talhaoId,
      'titulo': titulo,
      'dataInicioPlanejada': dataInicioPlanejada.toIso8601String(),
      'dataFimPlanejada': dataFimPlanejada.toIso8601String(),
      'status': status.name,
      'visitSessionId': visitSessionId,
      'serieId': serieId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  /// Converte para a entidade de domínio
  Event toEntity() {
    return Event(
      id: id,
      tipo: tipo,
      clienteId: clienteId,
      fazendaId: fazendaId,
      talhaoId: talhaoId,
      titulo: titulo,
      dataInicioPlanejada: dataInicioPlanejada,
      dataFimPlanejada: dataFimPlanejada,
      status: status,
      visitSessionId: visitSessionId,
      serieId: serieId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
    );
  }
}
