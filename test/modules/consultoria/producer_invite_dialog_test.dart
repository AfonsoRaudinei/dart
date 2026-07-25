import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_producer_invite_writer.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/producer_invite_dialog.dart';

class _FakeInviteWriter implements IProducerInviteWriter {
  _FakeInviteWriter({this.error});

  final Object? error;
  int calls = 0;

  @override
  Future<ProducerInviteData> createInvite(String clientId) async {
    calls += 1;
    if (error != null) throw error!;
    return ProducerInviteData(
      token: 'SF-ABCD-1234-EF56',
      expiresAt: DateTime.utc(2026, 8, 1),
    );
  }
}

void main() {
  testWidgets('gera token após ensureClientRemote e exibe valor', (
    tester,
  ) async {
    var ensureCalls = 0;
    final writer = _FakeInviteWriter();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProducerInviteDialog(
              clientId: 'client-1',
              clientName: 'Raudinei teste',
              ensureClientRemote: (_) async {
                ensureCalls += 1;
              },
              inviteWriter: writer,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Convite do produtor'), findsOneWidget);
    await tester.tap(find.text('Gerar token'));
    await tester.pumpAndSettle();

    expect(ensureCalls, 1);
    expect(writer.calls, 1);
    expect(find.text('SF-ABCD-1234-EF56'), findsOneWidget);
    expect(find.text('Gerar novo'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
  });

  testWidgets('mostra erro acionável quando ensureClientRemote falha', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProducerInviteDialog(
              clientId: 'client-1',
              clientName: 'Raudinei teste',
              ensureClientRemote: (_) async {
                throw Exception(
                  'Cliente ainda não sincronizado com a nuvem. Verifique a conexão e tente novamente.',
                );
              },
              inviteWriter: _FakeInviteWriter(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Gerar token'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Cliente ainda não sincronizado'),
      findsOneWidget,
    );
    expect(find.text('SF-ABCD-1234-EF56'), findsNothing);
  });
}
