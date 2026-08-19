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

    test(
      'P0: ações rápidas saem do FAB e vão para long press (sheet de publicação)',
      () {
        final privateMapSource =
            File('lib/ui/screens/private_map_screen.dart').readAsStringSync();
        final controlsOverlaySource = File(
          'lib/ui/components/map/widgets/map_controls_overlay.dart',
        ).readAsStringSync();

        expect(privateMapSource, contains('PublicationActionsBottomSheet'));
        expect(privateMapSource, contains('_handleMapLongPress'));
        expect(controlsOverlaySource.contains('MapActionFabMenu'), isFalse);
        // Descarte de ocorrência continua no MapBottomSheet (REGRA-OCC-2),
        // não mais via toggle FAB no orchestrator.
        expect(mapBottomSheetSource, contains('OccurrenceCloseCoordinator'));
      },
    );

    test('P0: host observa o pin antes do early-return do sheet', () {
      // pendingOccurrenceLocationProvider é autoDispose. Se o watch voltar para
      // depois do early-return, o LatLng gravado pelo long press com o sheet
      // ainda fechado é descartado e o usuário cai no placeholder
      // "Marque o ponto no mapa" em vez do formulário.
      final hostStart = performanceHostsSource.indexOf(
        'class MapBottomSheetOverlayHost',
      );
      expect(hostStart, greaterThan(-1));
      final hostSource = performanceHostsSource.substring(hostStart);

      final watchPin = hostSource.indexOf(
        'ref.watch(pendingOccurrenceLocationProvider)',
      );
      final earlyReturn = hostSource.indexOf(
        'return const SizedBox.shrink();',
      );

      expect(watchPin, greaterThan(-1));
      expect(earlyReturn, greaterThan(-1));
      expect(watchPin, lessThan(earlyReturn));
    });

    test('P1: guard do formulário não é publicado durante o build', () {
      // Escrever provider dentro do build dispara assert do Riverpod e mascara
      // falhas reais nos widget tests do host de ocorrência.
      expect(mapBottomSheetSource, contains('_publishOccurrenceFormGuard'));
      expect(
        mapBottomSheetSource,
        contains('WidgetsBinding.instance.addPostFrameCallback'),
      );
    });

    // ── Cenários de QA do long press → ações rápidas (Ago/2026) ────────────
    // Travam por contrato o que antes só era verificável em QA físico.

    test('QA-1: long press entrega o LatLng às 4 ações, sem armar modo', () {
      final privateMapSource =
          File('lib/ui/screens/private_map_screen.dart').readAsStringSync();

      // Resultado / Antes-Depois / Avaliação recebem a posição do gesto.
      expect(
        'position: latLng'.allMatches(privateMapSource).length,
        greaterThanOrEqualTo(3),
      );
      // Ocorrência recebe as coordenadas do mesmo gesto.
      expect(
        privateMapSource,
        contains('_openOccurrenceSheet(latLng.latitude, latLng.longitude)'),
      );
      // Nenhuma das 4 ações volta a armar modo antes de abrir o formulário.
      expect(privateMapSource, isNot(contains('_armMarketingMode')));
      expect(privateMapSource, isNot(contains('ArmedMode.marketing')));
    });

    test('QA-2: tap no mapa continua abrindo ocorrência via ArmedMode', () {
      final privateMapSource =
          File('lib/ui/screens/private_map_screen.dart').readAsStringSync();

      expect(privateMapSource, contains('ArmedMode.occurrences'));
      expect(orchestratorSource, contains('armedMode == ArmedMode.occurrences'));
    });

    test('QA-3: fechar o sheet limpa pin e guard (sem estado residual)', () {
      expect(
        performanceHostsSource,
        contains('ref.read(pendingOccurrenceLocationProvider.notifier).state = null'),
      );
      expect(
        performanceHostsSource,
        contains('ref.read(occurrenceFormGuardProvider.notifier).state = null'),
      );
    });

    test('QA-4: rascunho por pin sobrevive ao fechar o sheet', () {
      // autoDispose descartava o rascunho exatamente quando ele precisava
      // sobreviver: ninguém faz `watch` neste provider, só `read`.
      final draftProviderSource = File(
        'lib/modules/consultoria/occurrences/presentation/providers/occurrence_draft_provider.dart',
      ).readAsStringSync();

      expect(draftProviderSource, isNot(contains('StateProvider.autoDispose')));
      expect(draftProviderSource, contains('StateProvider.family'));
    });

    test('QA-5: rascunho não é gravado em dispose/deactivate', () {
      // Mexer em provider nesses lifecycles é proibido pelo Riverpod e lançava
      // StateError em produção; a persistência acontece a cada mutação.
      expect(creationSheetSource, isNot(contains('void deactivate()')));
      final disposeStart = creationSheetSource.indexOf('void dispose()');
      expect(disposeStart, greaterThan(-1));
      final disposeBody = creationSheetSource.substring(
        disposeStart,
        disposeStart + 500,
      );
      expect(disposeBody, isNot(contains('_persistDraft()')));
    });

    test('regression shield: arquivos de widget test presentes', () {
      expect(
        File(
          'test/ui/components/map/map_bottom_sheet_occurrence_host_test.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'test/modules/consultoria/occurrences/occurrence_draft_restore_test.dart',
        ).existsSync(),
        isTrue,
      );
    });
  });
}
