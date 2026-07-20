import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_radar_overlay_controller_provider.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/clima/infra/radar_overlay_controller_adapter.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';
import 'package:soloforte_app/ui/components/map/map_layers_sheet.dart';

void main() {
  group('LayersSheet ações operacionais', () {
    testWidgets('exibe e dispara somente o callback correspondente', (
      tester,
    ) async {
      var coordinateCalls = 0;
      var offlineCalls = 0;

      await _pumpLayersSheet(
        tester,
        onCoordinateSearch: () async => coordinateCalls++,
        onDownloadOfflineArea: () async => offlineCalls++,
      );

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('Baixar área offline'),
        120,
        scrollable: scrollable,
      );

      expect(find.text('Ir para coordenada'), findsOneWidget);
      expect(find.text('Baixar área offline'), findsOneWidget);

      await tester.tap(find.text('Ir para coordenada'));
      await tester.pump();
      expect(coordinateCalls, 1);
      expect(offlineCalls, 0);

      await tester.tap(find.text('Baixar área offline'));
      await tester.pump();
      expect(coordinateCalls, 1);
      expect(offlineCalls, 1);
    });

    testWidgets('oculta ações quando callbacks não são fornecidos', (
      tester,
    ) async {
      await _pumpLayersSheet(tester);

      expect(find.text('Ir para coordenada'), findsNothing);
      expect(find.text('Baixar área offline'), findsNothing);
    });

    testWidgets('exibe explicações para camadas avançadas WMS e Raster', (
      tester,
    ) async {
      await _pumpLayersSheet(tester);

      expect(find.textContaining('servidor WMS'), findsOneWidget);
      expect(find.textContaining('ortofoto, GeoTIFF'), findsOneWidget);
    });

    testWidgets('mantém pinos ativos por padrão', (tester) async {
      await _pumpLayersSheet(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LayersSheet)),
      );
      expect(container.read(showMarkersProvider), isTrue);
    });

    testWidgets('alterna camada ao tocar na miniatura, não só no rótulo', (
      tester,
    ) async {
      await _pumpLayersSheet(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LayersSheet)),
      );
      expect(container.read(activeLayerProvider), LayerType.satellite);

      final relevoLabel = tester.getCenter(find.text('Relevo'));
      await tester.tapAt(relevoLabel - const Offset(0, 28));
      await tester.pump();

      expect(container.read(activeLayerProvider), LayerType.relevo);
    });

    testWidgets('ativa chuva e troca para satélite quando estava em relevo', (
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
            radarOverlayControllerProvider.overrideWith((ref) {
              return RadarOverlayControllerAdapter(ref);
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 800,
                child: LayersSheet(onClose: () {}, renderTilePreviews: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LayersSheet)),
      );
      container.read(activeLayerProvider.notifier).setLayer(LayerType.relevo);
      await tester.pump();

      expect(container.read(activeLayerProvider), LayerType.relevo);
      expect(container.read(climaRadarEnabledProvider), isFalse);

      await tester.tap(find.text('Chuva'));
      await tester.pump();

      expect(container.read(climaRadarEnabledProvider), isTrue);
      expect(container.read(activeLayerProvider), LayerType.satellite);
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
      expect(
        find.textContaining('moldura verde no mapa marca a cobertura'),
        findsOneWidget,
      );
      expect(
        find.text('Baixar área visível').evaluate().isNotEmpty ||
            find
                .text('Download indisponível sem internet')
                .evaluate()
                .isNotEmpty,
        isTrue,
      );
    });
  });
}

Future<void> _pumpLayersSheet(
  WidgetTester tester, {
  Future<void> Function()? onCoordinateSearch,
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
        radarOverlayControllerProvider.overrideWith((ref) {
          return RadarOverlayControllerAdapter(ref);
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 1200,
            child: LayersSheet(
              onClose: () {},
              onCoordinateSearch: onCoordinateSearch,
              onDownloadOfflineArea: onDownloadOfflineArea,
              renderTilePreviews: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
