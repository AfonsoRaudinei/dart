import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/produtor/data/producer_property_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ProducerPropertyRepository', () {
    test('usa o id do usuário como client próprio do produtor', () {
      expect(
        ProducerPropertyRepository.ownClientIdForUser(
          '8c7a7a4a-1111-4222-8333-123456789abc',
        ),
        '8c7a7a4a-1111-4222-8333-123456789abc',
      );
    });

    test('resolve nome do produtor por metadata antes do email', () {
      final user = User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {'full_name': 'Produtor Teste'},
        aud: 'authenticated',
        createdAt: DateTime.utc(2026).toIso8601String(),
        email: 'produtor@soloforte.app',
      );

      expect(ProducerPropertyRepository.ownClientName(user), 'Produtor Teste');
    });

    test('usa email quando metadata não tem nome', () {
      final user = User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.utc(2026).toIso8601String(),
        email: 'produtor@soloforte.app',
      );

      expect(
        ProducerPropertyRepository.ownClientName(user),
        'produtor@soloforte.app',
      );
    });
  });
}
