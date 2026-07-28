import 'package:soloforte_app/core/contracts/i_visit_session_writer.dart';
import 'package:soloforte_app/core/contracts/visit_session_mirror_input.dart';

/// Fake [IVisitSessionWriter] para testes de use cases da agenda.
class FakeVisitSessionWriter implements IVisitSessionWriter {
  final List<VisitSessionMirrorInput> createdSessions = [];
  final List<(String sessionId, DateTime endTime)> finishedSessions = [];

  bool throwOnCreate = false;
  bool throwOnFinish = false;

  @override
  Future<void> createMirrorSession(VisitSessionMirrorInput input) async {
    if (throwOnCreate) {
      throw Exception('FakeVisitSessionWriter: erro simulado no espelho');
    }
    createdSessions.add(input);
  }

  @override
  Future<void> finishMirrorSession(String sessionId, DateTime endTime) async {
    if (throwOnFinish) {
      throw Exception('FakeVisitSessionWriter: erro simulado no encerramento');
    }
    finishedSessions.add((sessionId, endTime));
  }
}

/// No-op seguro quando o teste não valida espelhamento.
class NoopVisitSessionWriter implements IVisitSessionWriter {
  @override
  Future<void> createMirrorSession(VisitSessionMirrorInput input) async {}

  @override
  Future<void> finishMirrorSession(String sessionId, DateTime endTime) async {}
}
