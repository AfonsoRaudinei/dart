import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/session_models.dart';

void main() {
  test('SessionUnknown is distinct from public and authenticated', () {
    const unknown = SessionUnknown();
    const public = SessionPublic();
    const auth = SessionAuthenticated('token');

    expect(unknown, isNot(public));
    expect(unknown, isNot(auth));
    expect(public, isNot(auth));
  });
}
