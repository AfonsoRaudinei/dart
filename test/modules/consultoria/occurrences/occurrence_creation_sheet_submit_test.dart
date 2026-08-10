import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async => null;

  @override
  Future<List<ClientSummary>> listAtivos() async => const [];
}

class _EmptyVisitLookup implements IActiveVisitContextLookup {
  @override
  Future<ActiveVisitContext?> getActiveContext() async => null;
}

Widget _buildSheet({
  required OccurrenceConfirmCallback onConfirm,
  double latitude = -10.12345,
  double longitude = -48.54321,
}) {
  return ProviderScope(
    overrides: [
      currentUserRoleProvider.overrideWithValue(UserRole.consultor),
      clientLookupProvider.overrideWithValue(_FakeClientLookup()),
      activeVisitContextLookupProvider.overrideWithValue(_EmptyVisitLookup()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: OccurrenceCreationSheet(
          latitude: latitude,
          longitude: longitude,
          onConfirm: onConfirm,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('pin inválido (0,0) exibe erro inline sem chamar onConfirm', (
    tester,
  ) async {
    var confirmCalls = 0;

    await tester.pumpWidget(
      _buildSheet(
        latitude: 0,
        longitude: 0,
        onConfirm: (_) async {
          confirmCalls++;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar Ocorrência'));
    await tester.pumpAndSettle();

    expect(confirmCalls, 0);
    expect(find.byKey(const Key('occurrence_submit_error_banner')), findsOneWidget);
    expect(
      find.textContaining('Ponto do mapa inválido'),
      findsOneWidget,
    );
  });

  testWidgets('falha no onConfirm mantém formulário aberto com erro inline', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSheet(
        onConfirm: (_) async {
          throw StateError('Falha simulada no banco local.');
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Descreva a ocorrência…'),
      'Lagarta detectada',
    );
    await tester.pump();

    await tester.tap(find.text('Salvar Ocorrência'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(OccurrenceCreationSheet), findsOneWidget);
    expect(find.byKey(const Key('occurrence_submit_error_banner')), findsOneWidget);
    expect(find.text('Falha simulada no banco local.'), findsOneWidget);
    expect(find.text('Lagarta detectada'), findsOneWidget);
  });

  testWidgets('duplo toque em salvar dispara apenas uma tentativa', (
    tester,
  ) async {
    var confirmCalls = 0;

    await tester.pumpWidget(
      _buildSheet(
        onConfirm: (_) async {
          confirmCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Descreva a ocorrência…'),
      'Percevejo',
    );
    await tester.pump();

    await tester.tap(find.text('Salvar Ocorrência'));
    await tester.pump();
    await tester.tap(find.text('Salvar Ocorrência'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(confirmCalls, 1);
  });
}
