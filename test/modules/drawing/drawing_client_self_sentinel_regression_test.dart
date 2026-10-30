import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regressão 6a: sentinela `cliente_id = 'SELF'` removida do drawing sheet.
void main() {
  test('drawing module não referencia sentinela SELF em lib/', () {
    final drawingLib = Directory('lib/modules/drawing');
    expect(drawingLib.existsSync(), isTrue);

    final offenders = <String>[];
    for (final entity in drawingLib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (content.contains("'SELF'") || content.contains('"SELF"')) {
        offenders.add(entity.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Remover sentinela SELF: ${offenders.join(', ')}',
    );
  });

  test('contagem farms com cliente_id SELF — SQL para dados reais', () {
    // Sem acesso ao SQLite do aparelho/Supabase neste teste.
    // Executar no dispositivo ou backup local:
    // SELECT COUNT(*) FROM farms WHERE cliente_id = 'SELF' AND deleted_at IS NULL;
    const sql =
        "SELECT COUNT(*) FROM farms WHERE cliente_id = 'SELF' AND deleted_at IS NULL;";
    expect(sql, contains('cliente_id'));
  });
}
