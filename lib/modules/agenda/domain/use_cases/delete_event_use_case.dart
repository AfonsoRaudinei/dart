import '../entities/event.dart';
import '../enums/event_status.dart';
import '../repositories/i_agenda_repository.dart';

/// Caso de uso: soft delete de um evento da agenda.
///
/// Responsabilidades:
///   - Bloquear exclusão de eventos em andamento com sessão ativa
///   - Marcar sync_status = 'deleted' no repositório local
///   - NÃO executar hard delete (padrão offline-first)
///
/// O [SyncOrchestrator] processa a deleção remota quando houver conectividade.
/// A query de listagem filtra WHERE sync_status != 'deleted'.
class DeleteEventUseCase {
  final IAgendaRepository _repository;

  const DeleteEventUseCase(this._repository);

  /// Executa o soft delete do evento com [eventId].
  ///
  /// Lança [StateError] se o evento estiver em andamento com sessão ativa,
  /// pois finalizar a sessão é pré-requisito para exclusão.
  ///
  /// Lança [ArgumentError] se o evento não for encontrado.
  Future<void> execute(String eventId) async {
    final event = await _repository.getEventById(eventId);

    if (event == null) {
      throw ArgumentError('Evento não encontrado: $eventId');
    }

    _assertCanDelete(event);

    await _repository.deleteEvent(eventId);
  }

  /// Valida se o evento pode ser excluído.
  ///
  /// Regra: evento [emAndamento] com sessão de visita ativa não pode ser
  /// excluído diretamente — o usuário deve finalizar a sessão primeiro.
  void _assertCanDelete(Event event) {
    if (event.status == EventStatus.emAndamento &&
        event.visitSessionId != null) {
      throw StateError(
        'Não é possível excluir um evento em andamento com sessão ativa. '
        'Finalize ou cancele a sessão antes de excluir.',
      );
    }
  }
}
