// lib/core/contracts/i_visit_session_writer.dart
//
// Contrato neutro — espelha sessões da agenda em visit_sessions (ADR-048).
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// Implementado em visitas/infra/visit_session_writer_adapter.dart.
// Consumidores autorizados: agenda/ (use cases de início/fim de evento).

import 'visit_session_mirror_input.dart';

/// Escrita de sessões espelhadas para unificar IDs entre agenda e visitas.
abstract interface class IVisitSessionWriter {
  /// Cria linha em `visit_sessions` com o mesmo [VisitSessionMirrorInput.id]
  /// da sessão de agenda. Lança [ArgumentError] se [producerId] estiver vazio.
  Future<void> createMirrorSession(VisitSessionMirrorInput input);

  /// Encerra espelho em `visit_sessions` (`status = finished`, `end_time`).
  Future<void> finishMirrorSession(String sessionId, DateTime endTime);
}
