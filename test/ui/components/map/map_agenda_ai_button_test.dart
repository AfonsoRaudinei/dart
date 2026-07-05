import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/contracts/agenda_ai_recommendation_context.dart';
import 'package:soloforte_app/core/contracts/i_agenda_ai_launcher_provider.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_model.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_providers.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_resolver.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_agenda_ai_button.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
  });

  group('AgendaAiLaunchContext', () {
    test('locationPayload null quando sem coordenadas', () {
      const ctx = AgendaAiLaunchContext();
      expect(ctx.locationPayload, isNull);
      expect(ctx.hasLocation, isFalse);
    });

    test('locationPayload preenchido com lat/lon', () {
      const ctx = AgendaAiLaunchContext(latitude: -6.18, longitude: -35.35);
      expect(ctx.hasLocation, isTrue);
      expect(ctx.locationPayload, {'lat': -6.18, 'lon': -35.35});
    });
  });

  group('MapAgendaAiButton', () {
    testWidgets('oculto sem usuário autenticado', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MapAgendaAiButton()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('oculto quando flag desabilitada para usuário', (tester) async {
      const ffUser = FeatureFlagUser(
        userId: 'user-test',
        role: 'consultor',
        appVersion: '1.1.0',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAgendaAiEnabledProvider(ffUser).overrideWith((ref) async => false),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MapAgendaAiButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
    });
  });

  group('agendaAiLaunchContextProvider', () {
    test('inicia nulo e aceita contexto GPS', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(agendaAiLaunchContextProvider), isNull);

      const ctx = AgendaAiLaunchContext(latitude: 1, longitude: 2);
      container.read(agendaAiLaunchContextProvider.notifier).state = ctx;
      expect(container.read(agendaAiLaunchContextProvider), ctx);
    });
  });
}
