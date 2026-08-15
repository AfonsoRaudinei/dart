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
  });
}
