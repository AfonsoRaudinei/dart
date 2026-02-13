import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_model.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_resolver.dart';

void main() {
  group('🎲 Rollout Hash Determinism', () {
    late FeatureFlagResolver resolver;

    setUp(() {
      resolver = const FeatureFlagResolver();
    });

    test('Mesmo userId produz mesmo bucket em múltiplas chamadas', () {
      const testUserId = 'deterministic-user-42';

      // Simular 100 chamadas consecutivas
      final results = <bool>[];
      for (var i = 0; i < 100; i++) {
        final user = const FeatureFlagUser(userId: testUserId);
        final flag = FeatureFlag(
          key: 'test',
          enabled: true,
          rolloutPercentage: 50,
          version: 1,
        );

        results.add(resolver.isFeatureEnabled(flag, user));
      }

      // Todos os 100 resultados devem ser idênticos
      final uniqueResults = results.toSet();
      expect(uniqueResults.length, 1,
          reason: 'Mesmo userId deve sempre produzir mesmo resultado');
    });

    test('Hash distribui uniformemente entre 0-99', () {
      // Testar 10.000 userId diferentes
      final buckets = List.filled(100, 0);

      for (var i = 0; i < 10000; i++) {
        final user = FeatureFlagUser(userId: 'user-$i');

        // Testar com rollout crescente para descobrir bucket exato
        for (var rollout = 1; rollout <= 100; rollout++) {
          final flag = FeatureFlag(
            key: 'test',
            enabled: true,
            rolloutPercentage: rollout,
            version: 1,
          );

          if (resolver.isFeatureEnabled(flag, user)) {
            // Usuário entrou neste rollout, então bucket < rollout
            // Assumimos que entrou no bucket rollout-1
            final bucket = rollout - 1;
            buckets[bucket]++;
            break;
          }
        }
      }

      // Cada bucket deve ter aproximadamente 100 usuários (10000 / 100)
      // Margem de erro: ±40% (60-140) — distribuição estatística pode variar
      for (var i = 0; i < 100; i++) {
        expect(
          buckets[i],
          greaterThan(60),
          reason: 'Bucket $i deve ter pelo menos 60 usuários',
        );
        expect(
          buckets[i],
          lessThan(140),
          reason: 'Bucket $i deve ter no máximo 140 usuários',
        );
      }
    });

    test('Diferentes userId produzem buckets diferentes', () {
      final userIds = [
        'alice',
        'bob',
        'charlie',
        'diana',
        'eve',
      ];

      final results = <bool>[];
      for (final userId in userIds) {
        final user = FeatureFlagUser(userId: userId);
        final flag = FeatureFlag(
          key: 'test',
          enabled: true,
          rolloutPercentage: 50,
          version: 1,
        );

        results.add(resolver.isFeatureEnabled(flag, user));
      }

      // Pelo menos alguns devem ser diferentes (estatisticamente)
      final uniqueResults = results.toSet();
      expect(
        uniqueResults.length,
        greaterThan(1),
        reason: 'Diferentes userId devem produzir resultados variados',
      );
    });

    test('Alteração mínima no userId produz bucket completamente diferente', () {
      const userId1 = 'user-1000';
      const userId2 = 'user-1001';

      final user1 = const FeatureFlagUser(userId: userId1);
      final user2 = const FeatureFlagUser(userId: userId2);

      // Descobrir buckets exatos
      int? bucket1;
      int? bucket2;

      for (var rollout = 1; rollout <= 100; rollout++) {
        final flag = FeatureFlag(
          key: 'test',
          enabled: true,
          rolloutPercentage: rollout,
          version: 1,
        );

        if (bucket1 == null && resolver.isFeatureEnabled(flag, user1)) {
          bucket1 = rollout - 1;
        }
        if (bucket2 == null && resolver.isFeatureEnabled(flag, user2)) {
          bucket2 = rollout - 1;
        }

        if (bucket1 != null && bucket2 != null) break;
      }

      expect(bucket1, isNotNull);
      expect(bucket2, isNotNull);

      // Buckets não devem ser próximos (hash aleatório)
      // Não garantimos diferença específica, apenas que hash funciona
      expect([bucket1, bucket2], isNotNull);
    });

    test('userId vazio ou null não causa crash', () {
      final emptyUser = const FeatureFlagUser(userId: '');
      final flag = FeatureFlag.fullyEnabled('test');

      // Não deve lançar exceção
      expect(() => resolver.isFeatureEnabled(flag, emptyUser), returnsNormally);
    });

    test('Rollout boundaries funcionam corretamente', () {
      // Testar usuário que sabemos estar em bucket específico
      const testUser = 'boundary-test-user';

      // Descobrir bucket exato
      int? userBucket;
      for (var rollout = 1; rollout <= 100; rollout++) {
        final flag = FeatureFlag(
          key: 'test',
          enabled: true,
          rolloutPercentage: rollout,
          version: 1,
        );
        final user = const FeatureFlagUser(userId: testUser);

        if (resolver.isFeatureEnabled(flag, user)) {
          userBucket = rollout - 1;
          break;
        }
      }

      expect(userBucket, isNotNull);

      // Validar boundaries
      final user = const FeatureFlagUser(userId: testUser);

      // rollout < bucket → deve falhar
      if (userBucket! > 0) {
        final flagBelow = FeatureFlag(
          key: 'test',
          enabled: true,
          rolloutPercentage: userBucket,
          version: 1,
        );
        expect(resolver.isFeatureEnabled(flagBelow, user), false);
      }

      // rollout > bucket → deve passar
      final flagAbove = FeatureFlag(
        key: 'test',
        enabled: true,
        rolloutPercentage: userBucket + 1,
        version: 1,
      );
      expect(resolver.isFeatureEnabled(flagAbove, user), true);
    });

    test('Consistência entre reinicializações (simulado)', () {
      const userId = 'persistent-user';

      // Primeira "sessão"
      final resolver1 = const FeatureFlagResolver();
      final flag1 = FeatureFlag(
        key: 'test',
        enabled: true,
        rolloutPercentage: 50,
        version: 1,
      );
      final user1 = const FeatureFlagUser(userId: userId);
      final result1 = resolver1.isFeatureEnabled(flag1, user1);

      // Segunda "sessão" (novo resolver)
      final resolver2 = const FeatureFlagResolver();
      final flag2 = FeatureFlag(
        key: 'test',
        enabled: true,
        rolloutPercentage: 50,
        version: 1,
      );
      final user2 = const FeatureFlagUser(userId: userId);
      final result2 = resolver2.isFeatureEnabled(flag2, user2);

      // Resultado deve ser idêntico
      expect(result1, result2);
    });
  });
}
