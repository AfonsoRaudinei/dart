import 'package:soloforte_app/core/contracts/agenda_ai_recommendation_context.dart';
import 'package:soloforte_app/core/contracts/i_agenda_ai_visit_writer.dart';
import 'package:soloforte_app/modules/agenda/data/repositories/agenda_repository.dart';
import 'package:soloforte_app/modules/agenda/data/services/agenda_notification_service.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/visit.dart';
import 'package:soloforte_app/modules/agenda/domain/use_cases/create_event_use_case.dart';
import 'package:soloforte_app/modules/agenda/infra/agenda_domain_adapters.dart';

/// Cria visitas sugeridas pela IA via use case formal. ADR-046.
class AgendaAiVisitWriterAdapter implements IAgendaAiVisitWriter {
  AgendaAiVisitWriterAdapter(this._repository)
    : _createEventUseCase = CreateEventUseCase(
        AgendaRepositoryAdapter(_repository),
        AgendaNotificationServiceAdapter(AgendaNotificationService()),
      );

  final AgendaRepository _repository;
  final CreateEventUseCase _createEventUseCase;

  @override
  Future<void> createSuggestedVisit(AgendaAiSuggestedVisitRequest request) async {
    final currentEvents = await _repository.getAllEvents();
    await _createEventUseCase.execute(
      tipo: EventType.visitaTecnica,
      clienteId: request.clientId,
      titulo: request.titulo,
      dataInicioPlanejada: request.dataInicioPlanejada,
      dataFimPlanejada: request.dataFimPlanejada,
      currentUserId: request.currentUserId,
      priority: VisitPriority.normal,
      currentEvents: currentEvents,
    );
  }
}
