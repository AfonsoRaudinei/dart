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
          variant: SoloForteSheetVariant.ios,
          preserveMaterialDefaults: false,
          backgroundColor: Colors.transparent,
        ),
        SoloForteSheetSkinIos.background,
      );
    });

    test('tema Azul + null resolve para SoloForteSheetSkinIos.background', () {
      expect(
        resolveSoloForteSheetBackgroundColor(
          variant: SoloForteSheetVariant.ios,
          preserveMaterialDefaults: false,
          backgroundColor: null,
        ),
        SoloForteSheetSkinIos.background,
      );
    });

    test('tema Verde (light) resolve fundo claro', () {
      expect(
        resolveSoloForteSheetBackgroundColor(
          variant: SoloForteSheetVariant.light,
          preserveMaterialDefaults: false,
          backgroundColor: null,
        ),
        SoloForteSheetSkinLight.background,
      );
    });

    test('preserveMaterialDefaults: true não pinta prata com transparent', () {
      expect(
        resolveSoloForteSheetBackgroundColor(
          variant: SoloForteSheetVariant.ios,
          preserveMaterialDefaults: true,
          backgroundColor: Colors.transparent,
        ),
        Colors.transparent,
      );
    });

    test('tema Black mantém fundo escuro padrão', () {
      expect(
        resolveSoloForteSheetBackgroundColor(
          variant: SoloForteSheetVariant.dark,
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
      'kernel iOS não envolve conteúdo em Column-chrome (anti sheet duplo)',
      () {
        final source = File(
          'lib/core/ui/sheets/soloforte_sheet.dart',
        ).readAsStringSync();

        expect(source.contains('_SoloForteSheetChrome'), isFalse);
        expect(
          source.contains('Não envolve o conteúdo em `Column`+handle'),
          isTrue,
        );
        expect(source.contains('resolvedShowDragHandle = showDragHandle'), isTrue);
      },
    );

    test(
      'map_sheet_controller (check-in/layers) usa preserveMaterialDefaults',
      () {
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
        final source = File(
          'lib/modules/drawing/presentation/widgets/drawing_sheet.dart',
        ).readAsStringSync();

        expect(source.contains('SoloForteSheetVisuals.of(context)'), isTrue);
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

    test(
      'DrawingActionsBar / InfoEdit usam SoloForteSheetVisuals no tema Azul',
      () {
        final actions = File(
          'lib/modules/drawing/presentation/widgets/components/drawing_actions_bar.dart',
        ).readAsStringSync();
        final info = File(
          'lib/modules/drawing/presentation/widgets/drawing_info_edit_sheet.dart',
        ).readAsStringSync();
        final review = File(
          'lib/modules/drawing/presentation/widgets/drawing_sheet_builders_b.dart',
        ).readAsStringSync();

        expect(actions.contains('SoloForteSheetVisuals.of(context)'), isTrue);
        expect(info.contains('SoloForteSheetVisuals.of(context)'), isTrue);
        expect(review.contains('SoloForteSheetVisuals.of(context)'), isTrue);
      },
    );
  });
}
