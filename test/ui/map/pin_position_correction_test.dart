import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_sheet.dart';
import 'package:soloforte_app/ui/components/map/widgets/pin_position_correction_overlay.dart';
import 'package:soloforte_app/ui/screens/map/providers/pin_position_correction_provider.dart';

bool _occurrenceShowsPinCorrection(
  Occurrence occurrence, {
  required bool allowPinCorrection,
}) =>
    allowPinCorrection &&
    OccurrenceDetailSheet.occurrencePinCorrectionEligible(occurrence);

bool _marketingShowsPinCorrection(
  MarketingCase marketingCase, {
  required bool allowPinCorrection,
}) =>
    allowPinCorrection &&
    MarketingCaseSheet.marketingCasePinCorrectionEligible(marketingCase);

/// Keeps [pinPositionCorrectionProvider] alive after sheet pop (autoDispose).
class _PinCorrectionSessionWatcher extends ConsumerWidget {
  const _PinCorrectionSessionWatcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pinPositionCorrectionProvider);
    return const SizedBox.shrink();
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  tearDown(LocalSessionIdentity.resetForTesting);

  group('pin_position_correction', () {
    late FakeOccurrenceRepository fakeOccurrenceRepo;
    late _TrackingMarketingNotifier marketingNotifier;
    late ProviderContainer container;

    setUp(() {
      fakeOccurrenceRepo = FakeOccurrenceRepository();
      marketingNotifier = _TrackingMarketingNotifier();
      container = ProviderContainer(
        overrides: [
          occurrenceRepositoryProvider.overrideWithValue(fakeOccurrenceRepo),
          marketingCasesProvider.overrideWith((_) => marketingNotifier),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('updateCurrent moves session coordinates', () {
      pinCorrectionStartSession(
        container,
        kind: PinCorrectionKind.occurrence,
        entityId: 'occ-1',
        position: const LatLng(-10, -50),
        onConfirm: (_, __) async => true,
      );

      pinCorrectionUpdateCurrent(container, const LatLng(-11, -51));

      final session = container.read(pinPositionCorrectionProvider);
      expect(session?.current, const LatLng(-11, -51));
      expect(session?.original, const LatLng(-10, -50));
    });

    test('confirm occurrence persists and clears session', () async {
      final occurrence = _sampleOccurrence();
      pinCorrectionStartSession(
        container,
        kind: PinCorrectionKind.occurrence,
        entityId: occurrence.id,
        position: const LatLng(-10, -50),
        onConfirm: (newLat, newLng) async {
          await fakeOccurrenceRepo.updateOccurrence(
            occurrence.copyWith(
              lat: newLat,
              long: newLng,
              geometry: jsonEncode({
                'type': 'Point',
                'coordinates': [newLng, newLat],
              }),
            ),
          );
          return true;
        },
      );
      pinCorrectionUpdateCurrent(container, const LatLng(-12.5, -48.2));

      final saved = await pinCorrectionConfirm(container);

      expect(saved, isTrue);
      expect(fakeOccurrenceRepo.lastUpdated, isNotNull);
      expect(fakeOccurrenceRepo.lastUpdated!.lat, -12.5);
      expect(fakeOccurrenceRepo.lastUpdated!.long, -48.2);
      expect(container.read(pinPositionCorrectionProvider), isNull);
    });

    test('confirm marketing calls updateCase and clears session', () async {
      final marketingCase = _sampleMarketingCase(ownerUserId: 'user-1');
      pinCorrectionStartSession(
        container,
        kind: PinCorrectionKind.marketing,
        entityId: marketingCase.id,
        position: LatLng(marketingCase.lat, marketingCase.lng),
        onConfirm: (newLat, newLng) async {
          final updated = MarketingCase.fromJson({
            ...marketingCase.toJson(),
            'lat': newLat,
            'lng': newLng,
          });
          await marketingNotifier.updateCase(updated);
          return true;
        },
      );
      pinCorrectionUpdateCurrent(container, const LatLng(-15.2, -47.8));

      final saved = await pinCorrectionConfirm(container);

      expect(saved, isTrue);
      expect(marketingNotifier.lastUpdated, isNotNull);
      expect(marketingNotifier.lastUpdated!.lat, -15.2);
      expect(marketingNotifier.lastUpdated!.lng, -47.8);
      expect(container.read(pinPositionCorrectionProvider), isNull);
    });

    test('confirm occurrence returns false when onConfirm throws', () async {
      pinCorrectionStartSession(
        container,
        kind: PinCorrectionKind.occurrence,
        entityId: 'occ-1',
        position: const LatLng(-10, -50),
        onConfirm: (_, __) async {
          throw StateError('persist failed');
        },
      );

      final saved = await pinCorrectionConfirm(container);

      expect(saved, isFalse);
      expect(container.read(pinPositionCorrectionProvider), isNotNull);
    });

    test('startSession replaces active session (cancel-first)', () {
      pinCorrectionStartSession(
        container,
        kind: PinCorrectionKind.occurrence,
        entityId: 'occ-1',
        position: const LatLng(-10, -50),
        onConfirm: (_, __) async => true,
      );

      pinCorrectionStartSession(
        container,
        kind: PinCorrectionKind.marketing,
        entityId: 'mkt-2',
        position: const LatLng(-11, -51),
        onConfirm: (_, __) async => true,
      );

      final session = container.read(pinPositionCorrectionProvider);
      expect(session?.kind, PinCorrectionKind.marketing);
      expect(session?.entityId, 'mkt-2');
    });

    testWidgets('overlay shows snackbar when confirm fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        pinCorrectionStartSession(
                          ProviderScope.containerOf(context),
                          kind: PinCorrectionKind.occurrence,
                          entityId: 'occ-1',
                          position: const LatLng(-10, -50),
                          onConfirm: (_, __) async {
                            throw StateError('persist failed');
                          },
                        );
                      });
                      return const PinPositionCorrectionOverlay();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar posição'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Não foi possível salvar a posição. Verifique as coordenadas.',
        ),
        findsOneWidget,
      );
    });

    test('cancel discards session without repository calls', () async {
      pinCorrectionStartSession(
        container,
        kind: PinCorrectionKind.occurrence,
        entityId: 'occ-1',
        position: const LatLng(-10, -50),
        onConfirm: (_, __) async => true,
      );

      pinCorrectionCancel(container);

      expect(container.read(pinPositionCorrectionProvider), isNull);
      expect(fakeOccurrenceRepo.lastUpdated, isNull);
      expect(marketingNotifier.lastUpdated, isNull);
    });

    test('marketing guard hides correction for non-owner', () {
      LocalSessionIdentity.remember('owner-a');
      final caseOwnedByOther = _sampleMarketingCase(ownerUserId: 'owner-b');

      expect(
        MarketingCaseSheet.marketingCasePinCorrectionEligible(caseOwnedByOther),
        isFalse,
      );
    });

    test('marketing guard allows correction for owner', () {
      LocalSessionIdentity.remember('owner-a');
      final ownedCase = _sampleMarketingCase(ownerUserId: 'owner-a');

      expect(
        MarketingCaseSheet.marketingCasePinCorrectionEligible(ownedCase),
        isTrue,
      );
    });

    test('occurrence guard blocks read-only shared occurrence', () {
      final shared = _sampleOccurrence(cachedByUserId: 'shared-user');

      expect(
        OccurrenceDetailSheet.occurrencePinCorrectionEligible(shared),
        isFalse,
      );
    });

    test('occurrence guard allows editable occurrence with coordinates', () {
      final editable = _sampleOccurrence();

      expect(
        OccurrenceDetailSheet.occurrencePinCorrectionEligible(editable),
        isTrue,
      );
    });

    test('allowPinCorrection false hides occurrence action when eligible', () {
      final editable = _sampleOccurrence();

      expect(
        _occurrenceShowsPinCorrection(editable, allowPinCorrection: false),
        isFalse,
      );
      expect(
        _occurrenceShowsPinCorrection(editable, allowPinCorrection: true),
        isTrue,
      );
    });

    test('allowPinCorrection false hides marketing action when eligible', () {
      LocalSessionIdentity.remember('owner-a');
      final ownedCase = _sampleMarketingCase(ownerUserId: 'owner-a');

      expect(
        _marketingShowsPinCorrection(ownedCase, allowPinCorrection: false),
        isFalse,
      );
      expect(
        _marketingShowsPinCorrection(ownedCase, allowPinCorrection: true),
        isTrue,
      );
    });

    testWidgets(
      'occurrence detail sheet onConfirm persists via captured container',
      (tester) async {
        final occurrence = _sampleOccurrence();
        final testContainer = ProviderContainer(
          overrides: [
            occurrenceRepositoryProvider.overrideWithValue(fakeOccurrenceRepo),
            marketingCasesProvider.overrideWith((_) => marketingNotifier),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    Builder(
                      builder: (context) => TextButton(
                        onPressed: () => OccurrenceDetailSheet.show(
                          context,
                          occurrence,
                          allowPinCorrection: true,
                        ),
                        child: const Text('open-sheet'),
                      ),
                    ),
                    const _PinCorrectionSessionWatcher(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('open-sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Corrigir posição'), findsOneWidget);

        await tester.tap(find.text('Corrigir posição'));
        await tester.pumpAndSettle();

        expect(testContainer.read(pinPositionCorrectionProvider), isNotNull);

        pinCorrectionUpdateCurrent(testContainer, const LatLng(-12.5, -48.2));

        final saved = await pinCorrectionConfirm(testContainer);

        expect(saved, isTrue);
        expect(fakeOccurrenceRepo.lastUpdated, isNotNull);
        expect(fakeOccurrenceRepo.lastUpdated!.lat, -12.5);
        expect(fakeOccurrenceRepo.lastUpdated!.long, -48.2);
        expect(testContainer.read(pinPositionCorrectionProvider), isNull);

        testContainer.dispose();
      },
    );
  });
}

Occurrence _sampleOccurrence({String? cachedByUserId}) {
  return Occurrence(
    id: 'occ-1',
    type: 'Praga',
    description: 'Teste',
    lat: -10,
    long: -50,
    createdAt: DateTime(2026, 3, 1),
    cachedByUserId: cachedByUserId,
  );
}

MarketingCase _sampleMarketingCase({required String ownerUserId}) {
  final now = DateTime(2026, 3, 1);
  return MarketingCase(
    id: 'mkt-1',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -50,
    localizacaoTexto: 'Fazenda Teste',
    produtorFazenda: 'Produtor',
    produtoUtilizado: 'Produto',
    ownerUserId: ownerUserId,
    status: MarketingCaseStatus.published,
    criadoEm: now,
    atualizadoEm: now,
  );
}

class FakeOccurrenceRepository extends OccurrenceRepository {
  Occurrence? lastUpdated;

  @override
  Future<void> updateOccurrence(Occurrence occurrence) async {
    lastUpdated = occurrence;
  }
}

class _TrackingMarketingNotifier extends MarketingCasesNotifier {
  MarketingCase? lastUpdated;

  _TrackingMarketingNotifier()
    : super(_NoopMarketingRepo(), _NoopMarketingSync());

  @override
  Future<void> updateCase(MarketingCase updatedCase) async {
    lastUpdated = updatedCase;
  }

  @override
  Future<void> load({bool forceSync = false}) async {}
}

class _NoopMarketingRepo implements IMarketingCaseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopMarketingSync extends MarketingSyncService {
  _NoopMarketingSync() : super(_NoopMarketingRepo());
}
