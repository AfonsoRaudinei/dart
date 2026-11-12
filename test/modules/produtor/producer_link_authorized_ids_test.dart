import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_producer_invite_writer.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';

void main() {
  test('share fields e occurrences filtram clientes autorizados', () {
    final links = [
      ProducerClientLink(
        id: 'l1',
        consultorUserId: 'c1',
        clientId: 'client-a',
        producerUserId: 'p1',
        status: 'active',
        expiresAt: DateTime.utc(2026, 12, 1),
        usedAt: DateTime.utc(2026, 6, 1),
        createdAt: DateTime.utc(2026, 6, 1),
        updatedAt: DateTime.utc(2026, 6, 1),
        share: const ProducerShareSelection(
          fields: true,
          occurrences: false,
        ),
      ),
      ProducerClientLink(
        id: 'l2',
        consultorUserId: 'c1',
        clientId: 'client-b',
        producerUserId: 'p1',
        status: 'active',
        expiresAt: DateTime.utc(2026, 12, 1),
        usedAt: DateTime.utc(2026, 6, 1),
        createdAt: DateTime.utc(2026, 6, 1),
        updatedAt: DateTime.utc(2026, 6, 1),
        share: const ProducerShareSelection(
          fields: false,
          occurrences: true,
        ),
      ),
    ];

    final drawingClients = links
        .where((l) => l.share.fields)
        .map((l) => l.clientId)
        .toList();
    final occurrenceClients = links
        .where((l) => l.share.occurrences)
        .map((l) => l.clientId)
        .toList();

    expect(drawingClients, ['client-a']);
    expect(occurrenceClients, ['client-b']);
  });
}
