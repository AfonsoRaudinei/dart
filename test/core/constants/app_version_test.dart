import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/constants/app_version.dart';

void main() {
  test('kAppVersion padrão acompanha a versão do pubspec.yaml', () {
    // Em build de IPA, APP_VERSION é injetado pelo build_testflight.sh; o
    // padrão cobre simulador/dev e não pode ficar desatualizado.
    if (const bool.hasEnvironment('APP_VERSION')) return;
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(kAppVersion, match!.group(1));
  });
}
