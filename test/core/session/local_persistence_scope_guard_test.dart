import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guardrail: persistência local não pode depender só de
/// `Supabase.auth.currentUser` (some no bootstrap / logout→login).
///
/// Exceções intencionais:
/// - `local_session_identity.dart` (fonte da verdade)
/// - `session_controller.dart` (auth lifecycle)
/// - `drawing_remote_store.dart` / logs que checam sessão hidratada real
void main() {
  test(
    'repositórios/caches locais usam LocalSessionIdentity (sem currentUser cru)',
    () {
      final lib = Directory('lib');
      expect(lib.existsSync(), isTrue);

      final offenders = <String>[];
      final allowed = <String>{
        'lib/core/session/local_session_identity.dart',
        'lib/core/session/session_controller.dart',
        'lib/modules/drawing/data/data_sources/drawing_remote_store.dart',
        'lib/modules/drawing/data/data_sources/drawing_local_store.dart',
      };

      for (final file in lib.listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final rel = file.path.replaceFirst(RegExp(r'^.*?/lib/'), 'lib/');
        if (allowed.contains(rel)) continue;

        final text = file.readAsStringSync();
        if (text.contains('LocalSessionIdentity')) {
          // Já migrado — ok mesmo se ainda citar currentUser em outro contexto.
          continue;
        }

        final hits = RegExp(
          r"auth\.currentUser\?\.id",
        ).allMatches(text).length;
        if (hits == 0) continue;

        // Só flagra se o arquivo também fala em user_id / SQLite / cache local.
        final looksLocal =
            text.contains('user_id') ||
            text.contains('DatabaseHelper') ||
            text.contains('sqflite') ||
            text.contains('_database') ||
            text.contains('openDatabase');
        if (looksLocal) {
          offenders.add('$rel ($hits)');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Arquivos locais ainda usam auth.currentUser?.id sem '
            'LocalSessionIdentity:\n${offenders.join('\n')}',
      );
    },
  );
}
