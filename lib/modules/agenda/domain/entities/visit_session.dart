import 'package:equatable/equatable.dart';

/// Entidade representando uma Sessão de Visita
///
/// Responsável pela execução real de um evento.
/// Criada automaticamente quando um Event é iniciado.
class VisitSession extends Equatable {
  /// Identificador único da sessão
  final String id;

  /// ID do evento que originou esta sessão
  final String eventoId;

  /// Data/hora real de início da visita
  final DateTime startAtReal;

  /// Data/hora real de fim da visita (nullable enquanto em andamento)
  final DateTime? endAtReal;

  /// Duração calculada em minutos (nullable)
  final int? duracaoMin;

  /// Notas finais da visita
  final String? notasFinais;

  /// Snapshot do checklist aplicado (JSON serializado)
  final String? checklistSnapshot;

  /// Usuário que criou a sessão
  final String createdBy;

  /// Data de criação da sessão
  final DateTime createdAt;

  /// Status de sincronização offline
  final String syncStatus;

  const VisitSession({
    required this.id,
    required this.eventoId,
    required this.startAtReal,
    this.endAtReal,
    this.duracaoMin,
    this.notasFinais,
    this.checklistSnapshot,
    required this.createdBy,
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  /// Verifica se a sessão está em andamento
  bool get isActive {
    return endAtReal == null;
  }

  /// Calcula a duração em minutos se já foi finalizada
  int? get calculatedDurationMin {
    if (endAtReal == null) return null;
    return endAtReal!.difference(startAtReal).inMinutes;
  }

  /// Calcula a duração em andamento (em minutos)
  int get currentDurationMin {
    final end = endAtReal ?? DateTime.now();
    return end.difference(startAtReal).inMinutes;
  }

  /// Cria uma cópia da sessão com campos alterados
  VisitSession copyWith({
    String? id,
    String? eventoId,
    DateTime? startAtReal,
    DateTime? endAtReal,
    int? duracaoMin,
    String? notasFinais,
    String? checklistSnapshot,
    String? createdBy,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return VisitSession(
      id: id ?? this.id,
      eventoId: eventoId ?? this.eventoId,
      startAtReal: startAtReal ?? this.startAtReal,
      endAtReal: endAtReal ?? this.endAtReal,
      duracaoMin: duracaoMin ?? this.duracaoMin,
      notasFinais: notasFinais ?? this.notasFinais,
      checklistSnapshot: checklistSnapshot ?? this.checklistSnapshot,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventoId,
        startAtReal,
        endAtReal,
        duracaoMin,
        notasFinais,
        checklistSnapshot,
        createdBy,
        createdAt,
        syncStatus,
      ];
}
