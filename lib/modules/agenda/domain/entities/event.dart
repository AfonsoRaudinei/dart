import 'package:equatable/equatable.dart';
import '../enums/event_status.dart';
import '../enums/event_type.dart';

/// Entidade representando um Evento na Agenda
///
/// Responsável pelo planejamento de atividades.
/// Quando iniciado, cria automaticamente uma [VisitSession].
class Event extends Equatable {
  /// Identificador único do evento
  final String id;

  /// Tipo do evento
  final EventType tipo;

  /// ID do cliente relacionado
  final String clienteId;

  /// ID da fazenda relacionada (opcional)
  final String? fazendaId;

  /// ID do talhão relacionado (opcional)
  final String? talhaoId;

  /// Título/descrição do evento
  final String titulo;

  /// Data e hora planejada para início
  final DateTime dataInicioPlanejada;

  /// Data e hora planejada para fim
  final DateTime dataFimPlanejada;

  /// Status atual do evento
  final EventStatus status;

  /// ID da sessão de visita criada ao iniciar (nullable)
  final String? visitSessionId;

  /// ID da série (para recorrência futura)
  final String? serieId;

  /// Data de criação do evento
  final DateTime createdAt;

  /// Data da última atualização
  final DateTime updatedAt;

  /// Status de sincronização offline
  final String syncStatus;

  const Event({
    required this.id,
    required this.tipo,
    required this.clienteId,
    this.fazendaId,
    this.talhaoId,
    required this.titulo,
    required this.dataInicioPlanejada,
    required this.dataFimPlanejada,
    required this.status,
    this.visitSessionId,
    this.serieId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  /// Duração planejada em minutos
  int get duracaoPlanejadaMin {
    return dataFimPlanejada.difference(dataInicioPlanejada).inMinutes;
  }

  /// Verifica se o evento está no passado
  bool get isInPast {
    return dataFimPlanejada.isBefore(DateTime.now());
  }

  /// Verifica se o evento está acontecendo agora
  bool get isHappeningNow {
    final now = DateTime.now();
    return now.isAfter(dataInicioPlanejada) && now.isBefore(dataFimPlanejada);
  }

  /// Verifica se há conflito com outro evento
  bool hasConflictWith(Event other) {
    if (id == other.id) return false;

    // Verifica interseção de horários
    final thisStart = dataInicioPlanejada;
    final thisEnd = dataFimPlanejada;
    final otherStart = other.dataInicioPlanejada;
    final otherEnd = other.dataFimPlanejada;

    return thisStart.isBefore(otherEnd) && thisEnd.isAfter(otherStart);
  }

  /// Cria uma cópia do evento com campos alterados
  Event copyWith({
    String? id,
    EventType? tipo,
    String? clienteId,
    String? fazendaId,
    String? talhaoId,
    String? titulo,
    DateTime? dataInicioPlanejada,
    DateTime? dataFimPlanejada,
    EventStatus? status,
    String? visitSessionId,
    String? serieId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Event(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      clienteId: clienteId ?? this.clienteId,
      fazendaId: fazendaId ?? this.fazendaId,
      talhaoId: talhaoId ?? this.talhaoId,
      titulo: titulo ?? this.titulo,
      dataInicioPlanejada: dataInicioPlanejada ?? this.dataInicioPlanejada,
      dataFimPlanejada: dataFimPlanejada ?? this.dataFimPlanejada,
      status: status ?? this.status,
      visitSessionId: visitSessionId ?? this.visitSessionId,
      serieId: serieId ?? this.serieId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tipo,
        clienteId,
        fazendaId,
        talhaoId,
        titulo,
        dataInicioPlanejada,
        dataFimPlanejada,
        status,
        visitSessionId,
        serieId,
        createdAt,
        updatedAt,
        syncStatus,
      ];
}
