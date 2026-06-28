import '../../domain/entities/event.dart';
import '../../domain/entities/visit_session.dart';

/// Estado observável da agenda (eventos, sessões, conflitos).
class AgendaState {
  final List<Event> events;
  final List<VisitSession> sessions;
  final List<Event> conflicts;
  final bool isLoading;
  final String? error;

  const AgendaState({
    this.events = const [],
    this.sessions = const [],
    this.conflicts = const [],
    this.isLoading = false,
    this.error,
  });

  AgendaState copyWith({
    List<Event>? events,
    List<VisitSession>? sessions,
    List<Event>? conflicts,
    bool? isLoading,
    String? error,
  }) {
    return AgendaState(
      events: events ?? this.events,
      sessions: sessions ?? this.sessions,
      conflicts: conflicts ?? this.conflicts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
