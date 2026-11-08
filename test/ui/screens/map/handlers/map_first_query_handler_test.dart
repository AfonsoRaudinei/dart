import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/repositories/i_clients_repository.dart';
import 'package:soloforte_app/modules/drawing/infra/clients/i_clients_repository_provider.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/ui/components/map/map_sheet_state.dart';
import 'package:soloforte_app/ui/screens/map/handlers/map_first_query_handler.dart';

class _SpyDrawingRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => const [];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}

  @override
  Future<void> updateClientAreaTotal(String clientId, double areaTotal) async {}
}

class _ImportSpyController extends DrawingController {
  _ImportSpyController() : super(repository: _SpyDrawingRepository());

  int pickCount = 0;

  @override
  Future<void> pickImportFile() async {
    pickCount += 1;
  }
}

class _FakeClientsRepository implements IClientsRepository {
  @override
  Future<List<Client>> getClients() async => const [];

  @override
  Future<List<Farm>> getFarms(String clientId) async => const [];

  @override
  Future<void> saveFarm(Farm farm, String clientId) async {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
  });

  Future<
    ({
      WidgetRef ref,
      List<({MapSheetState state, String reason})> sheets,
      List<
        ({String drawingId, bool edit, bool union, bool ferramentasCompleto})
      >
      focuses,
    })
  >
  pumpHandlerHost(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
  }) async {
    final sheets = <({MapSheetState state, String reason})>[];
    final focuses =
        <
          ({String drawingId, bool edit, bool union, bool ferramentasCompleto})
        >[];
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingClientsRepositoryProvider.overrideWithValue(
            _FakeClientsRepository(),
          ),
          ...extraOverrides,
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return (ref: capturedRef, sheets: sheets, focuses: focuses);
  }

  void handle({
    required WidgetRef ref,
    required List<({MapSheetState state, String reason})> sheets,
    required List<
      ({String drawingId, bool edit, bool union, bool ferramentasCompleto})
    >
    focuses,
    required Uri uri,
    List<int>? mapMarks,
  }) {
    MapFirstQueryHandler.handle(
      uri: uri,
      ref: ref,
      setSheetState: (state, reason) =>
          sheets.add((state: state, reason: reason)),
      openMapMark: () => mapMarks?.add(1),
      focusDrawing:
          (
            drawingId, {
            required bool edit,
            bool union = false,
            bool ferramentasCompleto = false,
          }) async {
            focuses.add((
              drawingId: drawingId,
              edit: edit,
              union: union,
              ferramentasCompleto: ferramentasCompleto,
            ));
          },
      focusCoordinate: (LatLng point) {},
    );
  }

  testWidgets('modo=importar abre o arquivo e grava cliente e fazenda', (
    tester,
  ) async {
    final spy = _ImportSpyController();
    final host = await pumpHandlerHost(
      tester,
      extraOverrides: [drawingControllerProvider.overrideWith((ref) => spy)],
    );

    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse(
        '/map?modo=importar&clienteId=c1&clienteNome=Jonatha&fazendaId=f1&fazendaNome=Terra%20Viva',
      ),
    );
    await tester.pump();

    expect(host.sheets, hasLength(1));
    expect(host.sheets.single.state.type, MapSheetType.draw);
    expect(host.sheets.single.reason, 'query_param_modo_importar');
    expect(spy.pickCount, 1);
    final client = host.ref.read(drawingClientProvider);
    expect(client.preSelectedClientId, 'c1');
    expect(client.preSelectedClientName, 'Jonatha');
    expect(client.preSelectedFarmId, 'f1');
    expect(client.preSelectedFarmName, 'Terra Viva');
  });

  testWidgets('modo=editar NÃO chama setSheetState draw', (tester) async {
    final host = await pumpHandlerHost(tester);
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse('/map?modo=editar&clienteId=c1&fazendaId=f1&drawingId=d1'),
    );
    await tester.pump();

    expect(host.sheets, isEmpty);
    expect(host.focuses, hasLength(1));
    expect(host.focuses.single.drawingId, 'd1');
    expect(host.focuses.single.edit, isTrue);
    expect(host.focuses.single.union, isFalse);
  });

  testWidgets('modo=desenho com drawingId NÃO abre sheet no handle', (
    tester,
  ) async {
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

    expect(host.sheets, isEmpty);
    expect(host.focuses, hasLength(1));
    expect(host.focuses.single.edit, isFalse);
    expect(host.focuses.single.union, isFalse);
    expect(host.focuses.single.ferramentasCompleto, isFalse);
  });

  testWidgets('ferramentas=completo repassa flag ao focusDrawing', (
    tester,
  ) async {
    final host = await pumpHandlerHost(tester);
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse(
        '/map?modo=desenho&clienteId=c1&drawingId=d1&ferramentas=completo',
      ),
    );
    await tester.pump();

    expect(host.focuses.single.ferramentasCompleto, isTrue);
  });

  testWidgets('modo=desenho sem drawingId abre sheet de desenho', (
    tester,
  ) async {
    final host = await pumpHandlerHost(tester);
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse('/map?modo=desenho&clienteId=c1&fazendaId=f1'),
    );
    await tester.pump();

    expect(host.sheets, hasLength(1));
    expect(host.sheets.single.state.type, MapSheetType.draw);
    expect(host.sheets.single.reason, 'query_param_modo_desenho');
    expect(host.focuses, isEmpty);
  });

  testWidgets('modo=uniao com drawingId NÃO abre sheet no handle', (
    tester,
  ) async {
    final host = await pumpHandlerHost(tester);
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse('/map?modo=uniao&clienteId=c1&fazendaId=f1&drawingId=d1'),
    );
    await tester.pump();

    expect(host.sheets, isEmpty);
    expect(host.focuses, hasLength(1));
    expect(host.focuses.single.edit, isFalse);
    expect(host.focuses.single.union, isTrue);
  });

  testWidgets('modo=ocorrencia abre a ficha no GPS e não arma modo', (
    tester,
  ) async {
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
    expect(host.ref.read(mapNdviOverlayFieldIdProvider), isNull);
  });

  testWidgets('ndvi=1 grava o drawingId e outra rota limpa', (tester) async {
    final host = await pumpHandlerHost(tester);
    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse(
        '/map?modo=desenho&clienteId=c1&fazendaId=f1&drawingId=d1&ndvi=1',
      ),
    );
    await tester.pump();

    expect(host.ref.read(mapNdviOverlayFieldIdProvider), 'd1');
    expect(host.focuses.single.drawingId, 'd1');

    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse(
        '/map?modo=desenho&clienteId=c1&fazendaId=f1&drawingId=d1',
      ),
    );

    expect(host.ref.read(mapNdviOverlayFieldIdProvider), isNull);
  });

  testWidgets('ndvi=1 reseta mapNdviMonochromeEnabledProvider para false', (
    tester,
  ) async {
    final host = await pumpHandlerHost(tester);
    host.ref.read(mapNdviMonochromeEnabledProvider.notifier).state = true;

    handle(
      ref: host.ref,
      sheets: host.sheets,
      focuses: host.focuses,
      uri: Uri.parse(
        '/map?modo=desenho&clienteId=c1&fazendaId=f1&drawingId=d1&ndvi=1',
      ),
    );
    await tester.pump();

    expect(host.ref.read(mapNdviOverlayFieldIdProvider), 'd1');
    expect(host.ref.read(mapNdviMonochromeEnabledProvider), isFalse);
  });
}
