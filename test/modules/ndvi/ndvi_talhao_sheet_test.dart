import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';
import 'package:soloforte_app/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart';

void main() {
  const fieldId = 'F1';
  const fieldName = 'Talhão Teste';

  testWidgets('Estado loading — CircularProgressIndicator visível', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ndviImagesProvider(fieldId).overrideWith((ref) {
             return Future.delayed(const Duration(seconds: 1), () => <NdviImage>[]);
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NdviTalhaoSheet(fieldId: fieldId, fieldName: fieldName),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Resolve pending timer to avoid test failure
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Estado empty — texto "Nenhuma imagem" visível', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ndviImagesProvider(fieldId).overrideWith((ref) => <NdviImage>[]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NdviTalhaoSheet(fieldId: fieldId, fieldName: fieldName),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Nenhuma imagem disponível para este talhão'), findsOneWidget);
  });

  testWidgets('Estado com 1 imagem — ambas as setas desabilitadas', (tester) async {
    final images = [
      NdviImage(
        id: '1', fieldId: fieldId, imageDate: DateTime(2026, 1, 1),
        ndviMin: 0.1, ndviMax: 0.8, ndviMean: 0.5, source: 'auto',
        fetchedAt: DateTime.now(), syncStatus: 0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ndviImagesProvider(fieldId).overrideWith((ref) => images),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NdviTalhaoSheet(fieldId: fieldId, fieldName: fieldName),
          ),
        ),
      ),
    );

    await tester.pump();
    
    final leftArrow = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded));
    final rightArrow = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded));
    
    expect(leftArrow.onPressed, isNull);
    expect(rightArrow.onPressed, isNull);
  });

  testWidgets('Estado com 3 imagens — navegação correta', (tester) async {
    final images = [
      NdviImage(id: '3', fieldId: fieldId, imageDate: DateTime(2026, 3, 1), ndviMin: 0.1, ndviMax: 0.8, ndviMean: 0.7, source: 'auto', fetchedAt: DateTime.now(), syncStatus: 0),
      NdviImage(id: '2', fieldId: fieldId, imageDate: DateTime(2026, 2, 1), ndviMin: 0.1, ndviMax: 0.8, ndviMean: 0.6, source: 'auto', fetchedAt: DateTime.now(), syncStatus: 0),
      NdviImage(id: '1', fieldId: fieldId, imageDate: DateTime(2026, 1, 1), ndviMin: 0.1, ndviMax: 0.8, ndviMean: 0.5, source: 'auto', fetchedAt: DateTime.now(), syncStatus: 0),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ndviImagesProvider(fieldId).overrideWith((ref) => images),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NdviTalhaoSheet(fieldId: fieldId, fieldName: fieldName),
          ),
        ),
      ),
    );

    await tester.pump();
    
    // Index 0 (mais recente)
    expect(find.text('1 de 3 imagens'), findsOneWidget);
    
    final rightArrow = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded));
    expect(rightArrow.onPressed, isNull); // Não tem mais recente

    final leftArrow = find.widgetWithIcon(IconButton, Icons.chevron_left_rounded);
    await tester.tap(leftArrow);
    await tester.pump();
    
    expect(find.text('2 de 3 imagens'), findsOneWidget);
  });
}
