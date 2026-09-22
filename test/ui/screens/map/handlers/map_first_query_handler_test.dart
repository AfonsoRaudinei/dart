import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/domain/repositories/i_clients_repository.dart';
import 'package:soloforte_app/modules/drawing/infra/clients/i_clients_repository_provider.dart';
import 'package:soloforte_app/ui/components/map/map_sheet_state.dart';
import 'package:soloforte_app/ui/screens/map/handlers/map_first_query_handler.dart';

class _FakeClientsRepository implements IClientsRepository {
  @override
  Future<List<Client>> getClients() async => const [];

  @override
  Future<List<Farm>> getFarms(String clientId) async => const [];

  @override
  Future<void> saveFarm(Farm farm, String clientId) async {}
}

void main() {
  Future<
    ({
      WidgetRef ref,
      List<({MapSheetState state, String reason})> sheets,
      List<({String drawingId, bool edit, bool union})> focuses,
    })
  >
  pumpHandlerHost(WidgetTester tester) async {
    final sheets = <({MapSheetState state, String reason})>[];
    final focuses = <({String drawingId, bool edit, bool union})>[];
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingClientsRepositoryProvider.overrideWithValue(
            _FakeClientsRepository(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return (
      ref: capturedRef,
      sheets: sheets,
      focuses: focuses,
    );
  }

  void handle({
    required WidgetRef ref,
    required List<({MapSheetState state, String reason})> sheets,
    required List<({String drawingId, bool edit, bool union})> focuses,
    required Uri uri,
    List<int>? mapMarks,
  }) {
    MapFirstQueryHandler.handle(
      uri: uri,
      ref: ref,
      setSheetState: (state, reason) =>
          sheets.add((state: state, reason: reason)),
      openMapMark: () => mapMarks?.add(1),
      focusDrawing: (drawingId, {required bool edit, bool union = false}) async {
        focuses.add((drawingId: drawingId, edit: edit, union: union));
      },
      focusCoordinate: (LatLng point) {},
    );
  }

  testWidgets('modo=editar NÃO chama setSheetState draw', (tester) async {
    final host = await pumpHandlerHost(tester);
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse(
        '/map?modo=editar&clienteId=c1&fazendaId=f1&drawingId=d1',
      ),
    );
    await tester.pump();

    expect(host.sheets, isEmpty);
    expect(host.focuses, hasLength(1));
    expect(host.focuses.single.drawingId, 'd1');
    expect(host.focuses.single.edit, isTrue);
    expect(host.focuses.single.union, isFalse);
  });

  testWidgets('modo=desenho chama setSheetState draw', (tester) async {
    final host = await pumpHandlerHost(tester);
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse(
        '/map?modo=desenho&clienteId=c1&fazendaId=f1&drawingId=d1',
      ),
    );
    await tester.pump();

    expect(host.sheets, hasLength(1));
    expect(host.sheets.single.state.type, MapSheetType.draw);
    expect(host.sheets.single.reason, 'query_param_modo_desenho');
    expect(host.focuses, hasLength(1));
    expect(host.focuses.single.edit, isFalse);
    expect(host.focuses.single.union, isFalse);
  });

  testWidgets('modo=uniao chama setSheetState draw', (tester) async {
    final host = await pumpHandlerHost(tester);
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse(
        '/map?modo=uniao&clienteId=c1&fazendaId=f1&drawingId=d1',
      ),
    );
    await tester.pump();

    expect(host.sheets, hasLength(1));
    expect(host.sheets.single.state.type, MapSheetType.draw);
    expect(host.sheets.single.reason, 'query_param_modo_uniao');
    expect(host.focuses, hasLength(1));
    expect(host.focuses.single.edit, isFalse);
    expect(host.focuses.single.union, isTrue);
  });

  testWidgets('modo=ocorrencia abre a ficha no GPS e não arma modo', (tester) async {
    final host = await pumpHandlerHost(tester);
    final marks = <int>[];
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      mapMarks: marks,
      uri: Uri.parse('/map?modo=ocorrencia'),
    );
    await tester.pump();

    expect(marks, [1]);
    expect(host.sheets, isEmpty);
  });
}
