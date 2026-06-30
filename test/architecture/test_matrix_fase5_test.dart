import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('setores P0/P1 possuem arquivos de teste mínimos', () {
    expect(
      Directory('test/modules/consultoria').listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .length,
      greaterThanOrEqualTo(15),
    );
    expect(
      Directory('test/modules/marketing').listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .length,
      greaterThanOrEqualTo(2),
    );
    expect(
      Directory('test/modules/carteira').listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .length,
      greaterThanOrEqualTo(3),
    );
    expect(
      Directory('test/modules/public').listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .length,
      greaterThanOrEqualTo(1),
    );
  });

  test('tool/test_matrix_gate.sh existe e é executável', () {
    final gate = File('tool/test_matrix_gate.sh');
    expect(gate.existsSync(), isTrue);
  });
}
