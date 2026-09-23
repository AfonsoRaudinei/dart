import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_map_display_settings.dart';

void main() {
  testWidgets('chips de exibição ligam e desligam nome, cultura e área', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesService(
      await SharedPreferences.getInstance(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesServiceProvider.overrideWithValue(preferences)],
        child: const MaterialApp(
          home: Scaffold(body: ClientMapDisplaySettings()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClientMapDisplaySettings)),
    );

    expect(container.read(talhaoMapLabelPrefsProvider).showName, isTrue);
    expect(container.read(talhaoMapLabelPrefsProvider).showCultura, isTrue);
    expect(container.read(talhaoMapLabelPrefsProvider).showArea, isFalse);
    expect(find.text('Unidade de área'), findsNothing);

    await tester.tap(find.text('Área'));
    await tester.pump();
    expect(container.read(talhaoMapLabelPrefsProvider).showArea, isTrue);
    expect(find.text('ha'), findsOneWidget);

    await tester.tap(find.text('m²'));
    await tester.pump();
    expect(
      container.read(areaDisplayUnitProvider),
      AreaDisplayUnit.squareMeter,
    );

    await tester.tap(find.text('Nome'));
    await tester.tap(find.text('Cultura'));
    await tester.tap(find.text('Área'));
    await tester.pump();
    expect(container.read(talhaoMapLabelPrefsProvider).isHidden, isTrue);

    await tester.tap(find.text('Nome'));
    await tester.pump();
    expect(container.read(talhaoMapLabelPrefsProvider).showName, isTrue);
    expect(container.read(talhaoMapLabelPrefsProvider).isHidden, isFalse);
  });

  testWidgets('não repete unidade quando a tela já mostra o seletor', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'map_talhao_label_show_area_v2': true,
    });
    final preferences = PreferencesService(
      await SharedPreferences.getInstance(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesServiceProvider.overrideWithValue(preferences)],
        child: const MaterialApp(
          home: Scaffold(
            body: ClientMapDisplaySettings(showUnitSelector: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exibição no mapa'), findsOneWidget);
    expect(find.text('Unidade de área'), findsNothing);
    expect(find.text('ha'), findsNothing);
  });
}
