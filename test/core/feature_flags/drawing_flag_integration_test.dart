import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_model.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_resolver.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_service.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_sheet.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

/// Mock repository para testes
class MockDrawingRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}

  @override
  Future<void> deleteFeature(String id) async {}
}

/// ✅ Teste de Integração — Feature Flag + Drawing Module
///
/// Valida que:
/// 1. Feature flag desabilitada bloqueia acesso ao módulo
/// 2. Feature flag habilitada permite acesso normal
/// 3. Rollout por percentual funciona na prática
/// 4. Kill switch desativa imediatamente
void main() {
  group('🚦 Drawing Flag Integration', () {
    late FeatureFlagResolver resolver;

    setUp(() {
      resolver = const FeatureFlagResolver();
    });

    test('Flag desabilitada deve bloquear módulo Drawing', () {
      // Arrange
      final flag = FeatureFlag.disabled('drawing_v1');
      final user = const FeatureFlagUser(
        userId: 'test-user',
        role: 'consultor',
      );

      // Act
      final enabled = resolver.isDrawingEnabled(flag, user);

      // Assert
      expect(enabled, false);
    });

    test('Flag habilitada 100% deve permitir acesso', () {
      // Arrange
      final flag = FeatureFlag.fullyEnabled('drawing_v1');
      final user = const FeatureFlagUser(
        userId: 'test-user',
        role: 'consultor',
      );

      // Act
      final enabled = resolver.isDrawingEnabled(flag, user);

      // Assert
      expect(enabled, true);
    });

    test('Rollout 5% deve bloquear maioria dos usuários', () {
      // Arrange
      final flag = FeatureFlag(
        key: 'drawing_v1',
        enabled: true,
        rolloutPercentage: 5,
        allowedRoles: ['consultor'],
        version: 1,
      );

      // Testar 100 usuários
      int allowedCount = 0;
      for (var i = 0; i < 100; i++) {
        final user = FeatureFlagUser(
          userId: 'user-$i',
          role: 'consultor',
        );

        if (resolver.isDrawingEnabled(flag, user)) {
          allowedCount++;
        }
      }

      // Margem: 0-15 usuários (5% ± tolerância estatística)
      expect(allowedCount, greaterThanOrEqualTo(0));
      expect(allowedCount, lessThanOrEqualTo(15));
    });

    test('Kill switch instant rollback deve bloquear todos', () {
      // Arrange — Inicialmente em 100% rollout
      final flagBeforeKillSwitch = FeatureFlag(
        key: 'drawing_v1',
        enabled: true,
        rolloutPercentage: 100,
        version: 1,
      );

      final user = const FeatureFlagUser(userId: 'user-123');

      // Validar que estava permitido
      expect(resolver.isDrawingEnabled(flagBeforeKillSwitch, user), true);

      // Act — Kill switch ativado
      final flagAfterKillSwitch = FeatureFlag(
        key: 'drawing_v1',
        enabled: false, // 🔴 Kill switch
        rolloutPercentage: 100,
        version: 2,
      );

      final enabledAfter = resolver.isDrawingEnabled(flagAfterKillSwitch, user);

      // Assert
      expect(enabledAfter, false);
    });

    test('Papel não autorizado deve ser bloqueado', () {
      // Arrange
      final flag = FeatureFlag(
        key: 'drawing_v1',
        enabled: true,
        rolloutPercentage: 100,
        allowedRoles: ['consultor'],
        version: 1,
      );

      final produtor = const FeatureFlagUser(
        userId: 'produtor-001',
        role: 'produtor',
      );

      // Act
      final enabled = resolver.isDrawingEnabled(flag, produtor);

      // Assert
      expect(enabled, false);
    });

    test('Papel autorizado deve ser permitido', () {
      // Arrange
      final flag = FeatureFlag(
        key: 'drawing_v1',
        enabled: true,
        rolloutPercentage: 100,
        allowedRoles: ['consultor'],
        version: 1,
      );

      final consultor = const FeatureFlagUser(
        userId: 'consultor-001',
        role: 'consultor',
      );

      // Act
      final enabled = resolver.isDrawingEnabled(flag, consultor);

      // Assert
      expect(enabled, true);
    });

    testWidgets(
      '🎨 Widget deve renderizar se flag ativa',
      (WidgetTester tester) async {
        // Arrange
        final flag = FeatureFlag.fullyEnabled('drawing_v1');
        final user = const FeatureFlagUser(userId: 'user');
        final controller = DrawingController(repository: MockDrawingRepository());

        // Act — Renderizar widget condicionalmente
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: resolver.isDrawingEnabled(flag, user)
                    ? DrawingSheet(controller: controller)
                    : const Text('Módulo desabilitado'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert — Drawing sheet deve estar presente
        expect(find.text('Polígono'), findsOneWidget);
        expect(find.text('Módulo desabilitado'), findsNothing);

        controller.dispose();
      },
    );

    testWidgets(
      '🚫 Widget fallback deve aparecer se flag desabilitada',
      (WidgetTester tester) async {
        // Arrange
        final flag = FeatureFlag.disabled('drawing_v1');
        final user = const FeatureFlagUser(userId: 'user');
        final controller = DrawingController(repository: MockDrawingRepository());

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: resolver.isDrawingEnabled(flag, user)
                    ? DrawingSheet(controller: controller)
                    : const Text('Módulo desabilitado'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert — Fallback deve aparecer
        expect(find.text('Módulo desabilitado'), findsOneWidget);
        expect(find.text('Polígono'), findsNothing);

        controller.dispose();
      },
    );
  });

  group('🔧 FeatureFlagService Integration', () {
    test('Service deve retornar flag do backend simulado', () async {
      // Arrange — Mock backend response
      Future<Map<String, dynamic>> mockBackend() async {
        return {
          'flags': [
            {
              'key': 'drawing_v1',
              'enabled': true,
              'rollout_percentage': 50,
              'allowed_roles': ['consultor'],
              'version': 1,
            }
          ]
        };
      }

      final service = FeatureFlagService(
        fetchFromBackend: mockBackend,
        prefs: PreferencesService(await SharedPreferences.getInstance()),
      );

      // Act
      final flag = await service.getDrawingFlag();

      // Assert
      expect(flag.key, 'drawing_v1');
      expect(flag.enabled, true);
      expect(flag.rolloutPercentage, 50);
      expect(flag.allowedRoles, ['consultor']);

      service.dispose();
    });

    test('Service deve retornar disabled se backend falhar', () async {
      // Arrange — Mock backend failure
      Future<Map<String, dynamic>> mockBackend() async {
        throw Exception('Network error');
      }

      final service = FeatureFlagService(
        fetchFromBackend: mockBackend,
        prefs: PreferencesService(await SharedPreferences.getInstance()),
      );

      // Act
      final flag = await service.getDrawingFlag();

      // Assert — Fallback para disabled (safe default)
      expect(flag.key, 'drawing_v1');
      expect(flag.enabled, false);

      service.dispose();
    });
  });
}
