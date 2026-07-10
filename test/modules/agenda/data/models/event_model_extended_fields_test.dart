import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/data/models/event_model.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/visit.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';

void main() {
  test('EventModel round-trip preserva campos estendidos', () {
    final model = EventModel(
      id: 'e1',
      tipo: EventType.visitaTecnica,
      clienteId: 'c1',
      fazendaId: 'f1',
      talhaoId: 't1',
      titulo: 'Visita',
      dataInicioPlanejada: DateTime(2026, 7, 7, 8),
      dataFimPlanejada: DateTime(2026, 7, 7, 10),
      status: EventStatus.agendado,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
      syncStatus: 'pending',
      startTime: const TimeOfDay(hour: 8, minute: 30),
      endTime: const TimeOfDay(hour: 10, minute: 15),
      priority: VisitPriority.alta,
      latitude: -10.1,
      longitude: -48.2,
    );

    final json = model.toJson();
    final restored = EventModel.fromJson(json);

    expect(restored.startTime?.hour, 8);
    expect(restored.startTime?.minute, 30);
    expect(restored.endTime?.hour, 10);
    expect(restored.endTime?.minute, 15);
    expect(restored.priority, VisitPriority.alta);
    expect(restored.latitude, -10.1);
    expect(restored.longitude, -48.2);
  });
}
