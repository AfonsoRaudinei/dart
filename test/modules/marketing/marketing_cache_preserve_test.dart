import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/marketing_case_repository_impl.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';

MarketingCase _case(String id) {
  final now = DateTime.utc(2026, 7, 23);
  return MarketingCase(
    id: id,
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.ouro,
    lat: -15.0,
    lng: -47.0,
    localizacaoTexto: 'Fazenda Teste',
    produtorFazenda: 'Produtor',
    produtoUtilizado: 'Produto',
    status: MarketingCaseStatus.published,
    criadoEm: now,
    atualizadoEm: now,
    syncStatus: 'local_only',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('marketing_cache_guard');
    databaseFactory.setDatabasesPath(tempDir.path);
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
  });

  setUp(LocalSessionIdentity.resetForTesting);

  tearDown(LocalSessionIdentity.resetForTesting);

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'saveToCache sem user_id NÃO apaga cache existente (blindagem P0)',
    () async {
      LocalSessionIdentity.remember('user-a');
      final repo = MarketingCaseRepositoryImpl(Supabase.instance.client);
      await repo.saveToCache([_case('c1')]);

      final before = await repo.getLocalCases();
      expect(before.map((c) => c.id), contains('c1'));

      LocalSessionIdentity.clear();
      await repo.saveToCache([_case('should-not-write')]);

      LocalSessionIdentity.remember('user-a');
      final after = await repo.getLocalCases();
      expect(after.map((c) => c.id), contains('c1'));
      expect(after.map((c) => c.id), isNot(contains('should-not-write')));
    },
  );

  test(
    'getLocalCases sem user_id retorna vazio sem varrer/apagar cache',
    () async {
      LocalSessionIdentity.remember('user-b');
      final repo = MarketingCaseRepositoryImpl(Supabase.instance.client);
      await repo.saveSingleToCache(_case('c2'));

      LocalSessionIdentity.clear();
      expect(await repo.getLocalCases(), isEmpty);

      LocalSessionIdentity.remember('user-b');
      expect((await repo.getLocalCases()).map((c) => c.id), contains('c2'));
    },
  );
}
