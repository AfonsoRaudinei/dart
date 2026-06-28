import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/settings/data/models/user_profile_remote_patch.dart';
import 'package:soloforte_app/modules/settings/domain/entities/user_profile.dart';

void main() {
  final now = DateTime.utc(2026, 6, 17);
  final profile = UserProfile(
    id: 'user-1',
    email: 'user@example.com',
    fullName: 'Nome',
    phone: '63999999999',
    role: 'consultor',
    photoUrl: 'https://example.com/photo.jpg',
    creaNumber: 'CREA-123',
    createdAt: now,
    updatedAt: now,
  );

  group('UserProfile.copyWith', () {
    test('preserva campos omitidos', () {
      final result = profile.copyWith(
        updatedAt: now.add(const Duration(days: 1)),
      );

      expect(result.fullName, profile.fullName);
      expect(result.phone, profile.phone);
      expect(result.photoUrl, profile.photoUrl);
      expect(result.creaNumber, profile.creaNumber);
    });

    test('limpa cada campo anulavel explicitamente', () {
      expect(profile.copyWith(clearFullName: true).fullName, isNull);
      expect(profile.copyWith(clearPhone: true).phone, isNull);
      expect(profile.copyWith(clearPhotoUrl: true).photoUrl, isNull);
      expect(profile.copyWith(clearCreaNumber: true).creaNumber, isNull);
    });

    test('rejeita valor e flag de limpeza simultaneos', () {
      expect(
        () => profile.copyWith(fullName: 'Outro', clearFullName: true),
        throwsAssertionError,
      );
      expect(
        () => profile.copyWith(phone: '1', clearPhone: true),
        throwsAssertionError,
      );
      expect(
        () => profile.copyWith(
          photoUrl: 'https://example.com/new.jpg',
          clearPhotoUrl: true,
        ),
        throwsAssertionError,
      );
      expect(
        () => profile.copyWith(creaNumber: '2', clearCreaNumber: true),
        throwsAssertionError,
      );
    });
  });

  group('UserProfileRemotePatch', () {
    test('limpeza de nome e telefone gera strings vazias para perfis', () {
      final updated = profile.copyWith(clearFullName: true, clearPhone: true);
      final patch = UserProfileRemotePatch.fromUpdate(
        updated: updated,
        changedFields: {'fullName': profile.fullName, 'phone': profile.phone},
        updatedAt: now,
      );

      expect(patch.profileFields['name'], '');
      expect(patch.profileFields['phone'], '');
      expect(patch.userMetadata, isEmpty);
    });

    test('limpeza de CREA envia null ao metadata remoto', () {
      final updated = profile.copyWith(clearCreaNumber: true);
      final patch = UserProfileRemotePatch.fromUpdate(
        updated: updated,
        changedFields: {'creaNumber': profile.creaNumber},
        updatedAt: now,
      );

      expect(patch.hasUserMetadataChanges, isTrue);
      expect(patch.userMetadata, containsPair('crea_number', null));
      expect(patch.hasProfileChanges, isFalse);
    });

    test('nao inclui campos nao alterados', () {
      final patch = UserProfileRemotePatch.fromUpdate(
        updated: profile,
        changedFields: const {},
        updatedAt: now,
      );

      expect(patch.profileFields.keys, contains('updated_at'));
      expect(patch.profileFields, isNot(contains('name')));
      expect(patch.profileFields, isNot(contains('phone')));
      expect(patch.profileFields, isNot(contains('photo_url')));
      expect(patch.userMetadata, isEmpty);
    });
  });
}
