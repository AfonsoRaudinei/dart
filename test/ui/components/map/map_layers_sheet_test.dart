import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/ui/components/map/map_layer_preferences_section.dart';
import 'package:soloforte_app/ui/components/map/map_layers_sheet.dart';

void main() {
  group('LayersSheet ações operacionais', () {
    testWidgets('exibe e dispara o CTA compacto de download offline', (
      tester,
    ) async {
      var offlineCalls = 0;

      await _pumpLayersSheet(
        tester,
        onDownloadOfflineArea: () async => offlineCalls++,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LayersSheet)),
      );
      container
          .read(mapCameraSnapshotProvider.notifier)
          .state = MapCameraSnapshot(
        center: const LatLng(-10.0, -48.0),
        zoom: 14,
        visibleBounds: LatLngBounds(
          const LatLng(-10.1, -48.1),
          const LatLng(-9.9, -47.9),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('Baixar área'),
        120,
        scrollable: scrollable,
      );

      expect(find.text('Baixar área'), findsOneWidget);

      await tester.tap(find.text('Baixar área'));
      await tester.pump();
      expect(offlineCalls, 1);
    });

    testWidgets('não exibe fluxo ir para local (movido para chrome do mapa)', (
      tester,
    ) async {
      await _pumpLayersSheet(tester);

      expect(find.text('Ir para coordenada'), findsNothing);
      expect(find.text('Ir para município'), findsNothing);
      expect(find.text('Baixar área visível'), findsNothing);
    });

    testWidgets('exibe explicações de WMS e Raster em Configurações do mapa', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MapLayerPreferencesSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pinos no mapa'), findsOneWidget);
      expect(find.byKey(const Key('map_settings_show_pins')), findsOneWidget);
      expect(find.text('WMS Externa'), findsOneWidget);
      expect(find.textContaining('servidor WMS'), findsOneWidget);
      expect(find.text('Raster Custom (XYZ/GeoTIFF)'), findsOneWidget);
      expect(find.textContaining('GeoTIFF'), findsWidgets);
    });

    testWidgets('mantém pinos ativos por padrão', (tester) async {
      await _pumpLayersSheet(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LayersSheet)),
      );
      expect(container.read(showMarkersProvider), isTrue);
    });

    testWidgets('alterna pinos em Configurações do mapa', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MapLayerPreferencesSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapLayerPreferencesSection)),
      );
      expect(container.read(showMarkersProvider), isTrue);

      await tester.tap(find.byKey(const Key('map_settings_show_pins')));
      await tester.pump();

      expect(container.read(showMarkersProvider), isFalse);
    });

    testWidgets('não exibe toggle de chuva/radar no sheet de camadas', (
      tester,
    ) async {
      await _pumpLayersSheet(tester);

      expect(find.text('Chuva'), findsNothing);
      expect(find.text('Pinos'), findsNothing);
    });

    testWidgets('destaca status offline e CTA de download de forma visível', (
      tester,
    ) async {
      await _pumpLayersSheet(tester, onDownloadOfflineArea: () async {});

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LayersSheet)),
      );
      container
          .read(mapCameraSnapshotProvider.notifier)
          .state = MapCameraSnapshot(
        center: const LatLng(-10.0, -48.0),
        zoom: 14,
        visibleBounds: LatLngBounds(
          const LatLng(-10.1, -48.1),
          const LatLng(-9.9, -47.9),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mapa offline'), findsOneWidget);
      expect(find.text('Satélite • 0 áreas salvas'), findsOneWidget);
      expect(find.text('Baixar área'), findsOneWidget);
    });
  });
}

Future<void> _pumpLayersSheet(
  WidgetTester tester, {
  Future<void> Function()? onDownloadOfflineArea,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferencesService = PreferencesService(
    await SharedPreferences.getInstance(),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
        connectivityServiceProvider.overrideWithValue(
          const _FakeConnectivityService(initialValue: true),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 2200,
            child: LayersSheet(
              onClose: () {},
              onDownloadOfflineArea: onDownloadOfflineArea,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FakeConnectivityService implements ConnectivityService {
  const _FakeConnectivityService({required bool initialValue})
    : _initialValue = initialValue;

  final bool _initialValue;

  @override
  Stream<bool> get connectivityStream => const Stream<bool>.empty();

  @override
  Future<bool> get isConnected async => _initialValue;

  @override
  void dispose() {}
}
