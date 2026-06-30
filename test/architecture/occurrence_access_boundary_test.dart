import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consultoria nao importa produtor e usa contrato neutro', () {
    final files = Directory('lib/modules/consultoria')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final violations = files
        .where((file) => file.readAsStringSync().contains('modules/produtor/'))
        .map((file) => file.path)
        .toList();

    expect(violations, isEmpty);
    expect(
      File(
        'lib/modules/consultoria/occurrences/data/occurrence_sync_service.dart',
      ).readAsStringSync(),
      contains('IOccurrenceAccessReader'),
    );
  });
}
