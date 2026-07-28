import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_settings_sheet.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

void main() {
  group('ClimaSettingsSheet — padrão SoloForteSheetTokens', () {
    testWidgets('usa fundo escuro e título branco', (tester) async {
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
              body: ClimaSettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);

      final title = tester.widget<Text>(find.text('Configurações'));
      expect(title.style?.color, SoloForteSheetTokens.titleColor);

      final group = tester.widget<Container>(
        find.descendant(
          of: find.byType(ClimaSettingsSheet),
          matching: find.byType(Container).at(0),
        ),
      );
      final decoration = group.decoration! as BoxDecoration;
      expect(decoration.color, SoloForteSheetTokens.inputBackground);
    });

    testWidgets('opção selecionada usa chipTextActive', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
            climaUnidadeProvider.overrideWith((ref) => ClimaUnidade.celsius),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClimaSettingsSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final celsius = tester.widget<Text>(find.text('Celsius (°C)'));
      expect(celsius.style?.color, SoloForteSheetTokens.chipTextActive);
    });
  });
}
