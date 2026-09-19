import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/location_export_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('exibe opções de exportação de localização', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  LocationExportBottomSheet.show(
                    context: context,
                    latitude: -10.5,
                    longitude: -48.200001,
                    label: 'Área Visitada',
                  );
                },
                child: const Text('Abrir'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Exportar localização'), findsOneWidget);
    expect(find.text('-10.500000, -48.200001'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);
    expect(find.text('Apple Maps'), findsOneWidget);
    expect(find.text('Copiar coordenadas'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);
  });

  testWidgets('copiar coordenadas envia texto ao clipboard', (tester) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (message) async {
        if (message.method == 'Clipboard.setData') {
          clipboardText = message.arguments['text'] as String?;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  LocationExportBottomSheet.show(
                    context: context,
                    latitude: -10.5,
                    longitude: -48.200001,
                  );
                },
                child: const Text('Abrir'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar coordenadas'));
    await tester.pumpAndSettle();

    expect(clipboardText, '-10.500000, -48.200001');
  });
}
