import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import 'package:soloforte_app/modules/consultoria/relatorio_visita/data/occurrence_audio_remote.dart';

class _MemoryAudioStore implements OccurrenceAudioObjectStore {
  final uploads = <String, Uint8List>{};
  int uploadCalls = 0;
  int downloadCalls = 0;
  int removeCalls = 0;
  Object? uploadError;
  Object? downloadError;
  Object? removeError;
  Uint8List downloadBytes = Uint8List.fromList(const [1, 2, 3]);

  @override
  Future<void> upload(String objectPath, Uint8List bytes) async {
    uploadCalls++;
    final error = uploadError;
    if (error != null) throw error;
    uploads[objectPath] = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List> download(String objectPath) async {
    downloadCalls++;
    final error = downloadError;
    if (error != null) throw error;
    return uploads[objectPath] ?? downloadBytes;
  }

  @override
  Future<void> remove(String objectPath) async {
    removeCalls++;
    final error = removeError;
    if (error != null) throw error;
    uploads.remove(objectPath);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late _MemoryAudioStore store;
  late OccurrenceAudioRemote remote;

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('sf_occ_audio_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
            case 'getTemporaryDirectory':
            case 'getLibraryDirectory':
              return docs.path;
            default:
              return null;
          }
        });
    store = _MemoryAudioStore();
    remote = OccurrenceAudioRemote(store);
  });

  tearDown(() async {
    if (await docs.exists()) {
      await docs.delete(recursive: true);
    }
  });

  test('objectPath usa dono e id da ocorrência', () {
    expect(OccurrenceAudioRemote.objectPath('user', 'occ'), 'user/occ.m4a');
  });

  test('sem arquivo local não chama upload', () async {
    final empty = await remote.uploadIfLocal(
      userId: 'user',
      occurrenceId: 'occ',
      audioPath: '',
    );
    final missing = await remote.uploadIfLocal(
      userId: 'user',
      occurrenceId: 'occ',
      audioPath: 'media/nao_existe.m4a',
    );

    expect(empty, AudioUploadResult.skipped);
    expect(missing, AudioUploadResult.skipped);
    expect(store.uploadCalls, 0);
  });

  test(
    'arquivo local sobe na chave user/occ.m4a com os mesmos bytes',
    () async {
      final bytes = Uint8List.fromList(const [9, 8, 7, 6]);
      final file = File('${docs.path}/audio_local.m4a');
      await file.writeAsBytes(bytes);

      final result = await remote.uploadIfLocal(
        userId: 'user',
        occurrenceId: 'occ',
        audioPath: file.path,
      );

      expect(result, AudioUploadResult.uploaded);
      expect(store.uploadCalls, 1);
      expect(store.uploads['user/occ.m4a'], bytes);
    },
  );

  test('store que lança propaga em uploadIfLocal', () async {
    final file = File('${docs.path}/audio_falha.m4a');
    await file.writeAsBytes(const [1]);
    store.uploadError = StateError('rede');

    expect(
      remote.uploadIfLocal(
        userId: 'user',
        occurrenceId: 'occ',
        audioPath: file.path,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'download grava o relativo e a segunda chamada não baixa de novo',
    () async {
      store.downloadBytes = Uint8List.fromList(const [4, 5, 6]);
      const relative = 'media/audio_outro.m4a';

      final first = await remote.downloadIfMissing(
        userId: 'user',
        occurrenceId: 'occ',
        audioPath: relative,
        documentsDirectory: docs,
      );
      final saved = File('${docs.path}/$relative');

      expect(first, isTrue);
      expect(await saved.exists(), isTrue);
      expect(await saved.readAsBytes(), store.downloadBytes);
      expect(store.downloadCalls, 1);

      final second = await remote.downloadIfMissing(
        userId: 'user',
        occurrenceId: 'occ',
        audioPath: relative,
        documentsDirectory: docs,
      );

      expect(second, isTrue);
      expect(store.downloadCalls, 1);
    },
  );

  test('download que lança devolve false sem exceção', () async {
    store.downloadError = Exception('403');

    final ok = await remote.downloadIfMissing(
      userId: 'user',
      occurrenceId: 'occ',
      audioPath: 'media/audio_403.m4a',
      documentsDirectory: docs,
    );

    expect(ok, isFalse);
    expect(await File('${docs.path}/media/audio_403.m4a').exists(), isFalse);
  });

  test('upsert segue quando o upload sobe ou não há arquivo', () async {
    final bytes = Uint8List.fromList(const [3, 3]);
    final file = File('${docs.path}/audio_gate.m4a');
    await file.writeAsBytes(bytes);

    final uploaded = await shouldUpsertOccurrenceAfterAudio(
      audio: remote,
      userId: 'user',
      occurrenceId: 'occ',
      syncStatus: 'pending_sync',
      audioPath: file.path,
    );
    final skipped = await shouldUpsertOccurrenceAfterAudio(
      audio: remote,
      userId: 'user',
      occurrenceId: 'occ',
      syncStatus: 'pending_sync',
      audioPath: 'media/ausente.m4a',
    );

    expect(uploaded, isTrue);
    expect(skipped, isTrue);
    expect(store.uploads['user/occ.m4a'], bytes);
  });

  test('upload que lança não libera o upsert', () async {
    final file = File('${docs.path}/audio_gate_falha.m4a');
    await file.writeAsBytes(const [8]);
    store.uploadError = StateError('timeout');

    final allow = await shouldUpsertOccurrenceAfterAudio(
      audio: remote,
      userId: 'user',
      occurrenceId: 'occ',
      syncStatus: 'pending_sync',
      audioPath: file.path,
    );

    expect(allow, isFalse);
    expect(store.uploads.containsKey('user/occ.m4a'), isFalse);
  });

  test(
    'exclusão remove o objeto e segue o upsert mesmo se o remove falhar',
    () async {
      store.removeError = Exception('rede');

      final allow = await shouldUpsertOccurrenceAfterAudio(
        audio: remote,
        userId: 'user',
        occurrenceId: 'occ',
        syncStatus: 'deleted_local',
        audioPath: 'media/audio_x.m4a',
      );

      expect(allow, isTrue);
      expect(store.removeCalls, 1);
      expect(store.uploadCalls, 0);
    },
  );
}
