import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Testa `tool/sync_mac.sh` em repositórios git temporários (origin bare +
/// clone), com `flutter` falso no PATH. Não toca no repo real nem na rede.
void main() {
  final scriptPath = File('tool/sync_mac.sh').absolute.path;

  late Directory tmp;
  late Map<String, String> env;
  late String originPath;
  late String clonePath;
  late String pusherPath;

  ProcessResult git(String cwd, List<String> args) {
    final r = Process.runSync('git', args, workingDirectory: cwd, environment: env);
    if (r.exitCode != 0) {
      fail('git ${args.join(' ')} falhou em $cwd: ${r.stderr}');
    }
    return r;
  }

  String sha(String cwd, String ref) =>
      (git(cwd, ['rev-parse', ref]).stdout as String).trim();

  void commitFile(String cwd, String name, String content) {
    File('$cwd/$name').writeAsStringSync(content);
    git(cwd, ['add', name]);
    git(cwd, ['commit', '-m', 'add $name']);
  }

  /// Novo commit no origin/main, via um clone auxiliar.
  void advanceOrigin(String name) {
    commitFile(pusherPath, name, name);
    git(pusherPath, ['push', 'origin', 'main']);
  }

  ProcessResult runSync(String cwd) =>
      Process.runSync('bash', [scriptPath, '--quiet'],
          workingDirectory: cwd, environment: env);

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('sync_mac_test_');

    final fakeBin = Directory('${tmp.path}/bin')..createSync();
    final fakeFlutter = File('${fakeBin.path}/flutter')
      ..writeAsStringSync('#!/usr/bin/env bash\nexit 0\n');
    Process.runSync('chmod', ['+x', fakeFlutter.path]);

    env = {
      'PATH': '${fakeBin.path}:${Platform.environment['PATH'] ?? ''}',
      'HOME': tmp.path,
      'GIT_CONFIG_GLOBAL': '/dev/null',
      'GIT_CONFIG_SYSTEM': '/dev/null',
      'GIT_CONFIG_NOSYSTEM': '1',
      'GIT_AUTHOR_NAME': 'Test',
      'GIT_AUTHOR_EMAIL': 'test@example.com',
      'GIT_COMMITTER_NAME': 'Test',
      'GIT_COMMITTER_EMAIL': 'test@example.com',
      'GIT_TERMINAL_PROMPT': '0',
    };

    originPath = '${tmp.path}/origin.git';
    clonePath = '${tmp.path}/clone';
    pusherPath = '${tmp.path}/pusher';

    git(tmp.path, ['init', '--bare', '-b', 'main', originPath]);
    git(tmp.path, ['clone', originPath, pusherPath]);
    git(pusherPath, ['checkout', '-B', 'main']);
    commitFile(pusherPath, 'base.txt', 'base');
    git(pusherPath, ['push', '-u', 'origin', 'main']);
    git(tmp.path, ['clone', originPath, clonePath]);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('em cursor/x mantém a branch e avança o ref local main', () {
    git(clonePath, ['checkout', '-b', 'cursor/x']);
    advanceOrigin('novo.txt');
    final originSha = sha(pusherPath, 'HEAD');
    expect(sha(clonePath, 'main'), isNot(originSha));

    final r = runSync(clonePath);

    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      (git(clonePath, ['branch', '--show-current']).stdout as String).trim(),
      'cursor/x',
    );
    expect(sha(clonePath, 'main'), originSha);
    expect(File('$clonePath/novo.txt').existsSync(), isFalse,
        reason: 'working tree da branch não deve mudar');
  });

  test('em main faz pull e avança', () {
    advanceOrigin('novo.txt');
    final originSha = sha(pusherPath, 'HEAD');

    final r = runSync(clonePath);

    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      (git(clonePath, ['branch', '--show-current']).stdout as String).trim(),
      'main',
    );
    expect(sha(clonePath, 'HEAD'), originSha);
    expect(File('$clonePath/novo.txt').existsSync(), isTrue);
  });

  test('working tree sujo em cursor/x continua intacto', () {
    git(clonePath, ['checkout', '-b', 'cursor/x']);
    File('$clonePath/sujo.txt').writeAsStringSync('nao commitado');
    File('$clonePath/base.txt').writeAsStringSync('modificado');
    advanceOrigin('novo.txt');

    final r = runSync(clonePath);

    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(File('$clonePath/sujo.txt').readAsStringSync(), 'nao commitado');
    expect(File('$clonePath/base.txt').readAsStringSync(), 'modificado');
    expect(
      (git(clonePath, ['branch', '--show-current']).stdout as String).trim(),
      'cursor/x',
    );
  });

  test('main local divergida: avisa em stderr, sai 0 e não força', () {
    git(clonePath, ['checkout', '-b', 'cursor/x']);
    git(clonePath, ['checkout', 'main']);
    commitFile(clonePath, 'local.txt', 'local');
    final divergedSha = sha(clonePath, 'main');
    git(clonePath, ['checkout', 'cursor/x']);
    advanceOrigin('novo.txt');

    final r = runSync(clonePath);

    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stderr as String, contains('divergiu'));
    expect(sha(clonePath, 'main'), divergedSha);
    expect(
      (git(clonePath, ['branch', '--show-current']).stdout as String).trim(),
      'cursor/x',
    );
  });
}
