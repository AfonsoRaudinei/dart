import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/planos/data/services/plano_local_cache.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

void main() {
  group('PlanoLocalCache', () {
    late DateTime now;
    late PreferencesService prefs;
    late PlanoLocalCache cache;

    const userId = 'user-cache-1';

    UserPlan plan({String id = 'plan-1'}) => UserPlan(
          id: id,
          userId: userId,
          plano: PlanoTipo.prata,
          origem: PlanoOrigem.pagamento,
          ativo: true,
          iniciouEm: DateTime.utc(2026, 8, 1),
          expiraEm: DateTime.utc(2027, 8, 1),
          criadoEm: DateTime.utc(2026, 8, 1),
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      now = DateTime.utc(2026, 9, 5, 12);
      prefs = PreferencesService(await SharedPreferences.getInstance());
      cache = PlanoLocalCache(
        prefs,
        now: () => now,
        ttl: const Duration(hours: 24),
      );
    });

    test('save + readValid retorna o plano dentro do TTL', () async {
      await cache.save(plan());

      final cached = cache.readValid(userId);
      expect(cached, isNotNull);
      expect(cached!.id, 'plan-1');
      expect(cached.userId, userId);
      expect(cached.plano, PlanoTipo.prata);
      expect(cache.isExpired(userId), isFalse);
    });

    test('readValid é miss e isExpired é true após o TTL', () async {
      await cache.save(plan());
      now = now.add(const Duration(hours: 24));

      expect(cache.readValid(userId), isNull);
      expect(cache.isExpired(userId), isTrue);
    });

    test('readValid é miss quando nunca houve verificação', () {
      expect(cache.readValid(userId), isNull);
      expect(cache.isExpired(userId), isFalse);
    });

    test('JSON corrompido é tratado como miss, sem throw', () async {
      await prefs.setString('plano_cache_v1_$userId', '{not-json');
      await prefs.setInt(
        'plano_cache_v1_${userId}_verified_at',
        now.millisecondsSinceEpoch,
      );

      expect(cache.readValid(userId), isNull);
    });

    test('clear remove o cache do userId', () async {
      await cache.save(plan());
      await cache.clear(userId);

      expect(cache.readValid(userId), isNull);
      expect(cache.isExpired(userId), isFalse);
    });
  });
}
