import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

/// REGRA-SHEET-BLAST-1 — contrato de resolução de fundo do sheet (IPA 210).
void main() {
  group('REGRA-SHEET-BLAST-1 soloforte_sheet contract', () {
    test('tema Azul + transparent resolve para SoloForteSheetSkinIos.background', () {
      expect(
        resolveSoloForteSheetBackgroundColor(
          isIos: true,
          preserveMaterialDefaults: false,
          backgroundColor: Colors.transparent,
        ),
        SoloForteSheetSkinIos.background,
      );
    });

    test('tema Azul + null resolve para SoloForteSheetSkinIos.background', () {
      expect(
        resolveSoloForteSheetBackgroundColor(
          isIos: true,
          preserveMaterialDefaults: false,
          backgroundColor: null,
        ),
        SoloForteSheetSkinIos.background,
      );
    });

    test('preserveMaterialDefaults: true não pinta prata com transparent', () {
      expect(
        resolveSoloForteSheetBackgroundColor(
          isIos: true,
          preserveMaterialDefaults: true,
          backgroundColor: Colors.transparent,
        ),
        Colors.transparent,
      );
    });

    test('tema escuro (não iOS) mantém fundo escuro padrão', () {
      expect(
        resolveSoloForteSheetBackgroundColor(
          isIos: false,
          preserveMaterialDefaults: false,
          backgroundColor: null,
        ),
        SoloForteSheetTokens.sheetBackground,
      );
    });

    test('soloforte_sheet.dart expõe resolveSoloForteSheetBackgroundColor', () {
      final source = File(
        'lib/core/ui/sheets/soloforte_sheet.dart',
      ).readAsStringSync();

      expect(source.contains('resolveSoloForteSheetBackgroundColor'), isTrue);
      expect(source.contains('SoloForteSheetSkinIos.background'), isTrue);
      expect(source.contains('Colors.transparent'), isTrue);
    });

    test(
      'map_sheet_controller (check-in/layers) usa preserveMaterialDefaults',
      () {
        // Host com DraggableScrollableSheet: sem o flag, tema Azul colapsa
        // o sheet (tela branca no check-in). REGRA-SHEET-BLAST-1.
        final source = File(
          'lib/ui/screens/map/controllers/map_sheet_controller.dart',
        ).readAsStringSync();

        expect(source.contains('backgroundColor: Colors.transparent'), isTrue);
        expect(source.contains('preserveMaterialDefaults: true'), isTrue);
        expect(source.contains('MapSheetType.checkIn'), isTrue);
      },
    );

    test(
      'DrawingSheet não força sheetBackground escuro quando tema Azul',
      () {
        // Imagem 3 regressão: painel #1C1C1E aninhado no chrome prata.
        final source = File(
          'lib/modules/drawing/presentation/widgets/drawing_sheet.dart',
        ).readAsStringSync();

        expect(source.contains('soloForteSheetIsIos(context)'), isTrue);
        expect(source.contains('Colors.transparent'), isTrue);
        expect(
          source.contains(
            'color: SoloForteSheetTokens.sheetBackground,\n'
            '          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),',
          ),
          isFalse,
        );
      },
    );
  });
}
