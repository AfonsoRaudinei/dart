import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BUG-006 — Ocorrência no mapa: sheet preso, perda de dados após foto (P0/P1).
///
/// Se qualquer teste aqui quebrar, o fix de criação de ocorrência REGREDIU.
void main() {
  group('BUG-006 occurrence_creation_flow_regression', () {
    late String mapBottomSheetSource;
    late String uiHelpersSource;
    late String performanceHostsSource;
    late String orchestratorSource;
    late String creationSheetSource;

    setUp(() {
      mapBottomSheetSource =
          File('lib/ui/components/map/map_bottom_sheet.dart').readAsStringSync();
      uiHelpersSource = File(
        'lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_ui_helpers.dart',
      ).readAsStringSync();
      performanceHostsSource = File(
        'lib/ui/screens/map/widgets/map_performance_hosts.dart',
      ).readAsStringSync();
      orchestratorSource = File(
        'lib/ui/screens/map/widgets/map_build_orchestrator.dart',
      ).readAsStringSync();
      creationSheetSource = File(
        'lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart',
      ).readAsStringSync();
    });

    test('P0: criação abre expandida — sem altura hardcoded 350px', () {
      expect(mapBottomSheetSource, contains('_resolveInitialDetent'));
      expect(mapBottomSheetSource, contains('SheetDetent.expanded'));
      expect(mapBottomSheetSource, contains('isCreatingOccurrence'));
      expect(mapBottomSheetSource, isNot(contains('final initialHeight = 350.0')));
    });

    test('P0: dismiss passa pelo OccurrenceCloseCoordinator', () {
      expect(mapBottomSheetSource, contains('OccurrenceCloseCoordinator'));
      expect(mapBottomSheetSource, contains('confirmDiscardIfDirty'));
      expect(
        File(
          'lib/modules/consultoria/occurrences/presentation/coordinators/occurrence_close_coordinator.dart',
        ).existsSync(),
        isTrue,
      );
    });

    test('P0: foto fecha modal de origem antes do ImagePicker', () {
      expect(uiHelpersSource, contains('Navigator.of(sheetContext).pop()'));
      expect(uiHelpersSource, contains('_capturePhotoFromSource'));
      expect(
        uiHelpersSource.indexOf('Navigator.of(sheetContext).pop()'),
        lessThan(uiHelpersSource.indexOf('_picker.pickImage')),
      );
    });

    test('P1: showContent relaxado na criação de ocorrência', () {
      expect(mapBottomSheetSource, contains('_shouldShowSheetContent'));
      expect(mapBottomSheetSource, contains('isCreatingOccurrence'));
      expect(mapBottomSheetSource, contains('_tabContentKey'));
    });

    test('P1: rascunho keyed por pin existe no módulo consultoria', () {
      expect(
        File(
          'lib/modules/consultoria/occurrences/presentation/models/occurrence_form_draft.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/modules/consultoria/occurrences/presentation/providers/occurrence_draft_provider.dart',
        ).existsSync(),
        isTrue,
      );
      expect(creationSheetSource, contains('_restoreDraftIfAny'));
      expect(creationSheetSource, contains('_persistDraft'));
    });

    test('P1: onClose do host NÃO limpa rascunho indiscriminadamente', () {
      expect(performanceHostsSource, isNot(contains('clearOccurrenceDraft')));
    });

    test('P0: toggle FAB confirma descarte quando formulário está aberto', () {
      expect(orchestratorSource, contains('OccurrenceCloseCoordinator'));
      expect(orchestratorSource, contains('clearOccurrenceDraft'));
      expect(orchestratorSource, contains('isCreatingOccurrence'));
    });

    test('regression shield: arquivo de teste do coordinator presente', () {
      expect(
        File(
          'test/modules/consultoria/occurrences/occurrence_close_coordinator_test.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'test/modules/consultoria/occurrences/occurrence_form_draft_test.dart',
        ).existsSync(),
        isTrue,
      );
    });
  });
}
