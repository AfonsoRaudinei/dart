import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_delete_guard.dart';

void main() {
  test('ensureFarmDeletable permite exclusão sem talhões', () {
    expect(() => ensureFarmDeletable(linkedFieldCount: 0), returnsNormally);
  });

  test('ensureFarmDeletable bloqueia exclusão com talhões vinculados', () {
    expect(
      () => ensureFarmDeletable(linkedFieldCount: 1),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'Remova os talhões antes de excluir a fazenda.',
        ),
      ),
    );
  });
}
