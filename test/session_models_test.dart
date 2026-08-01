import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _testUser() => User.fromJson(const {
      'id': 'user-session-models',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-07-20T12:00:00.000Z',
    })!;

void main() {
  test('SessionUnknown is distinct from public and authenticated', () {
    const unknown = SessionUnknown();
    const public = SessionPublic();
    final auth = SessionAuthenticated(_testUser());

    expect(unknown, isNot(public));
    expect(unknown, isNot(auth));
    expect(public, isNot(auth));
  });
}
