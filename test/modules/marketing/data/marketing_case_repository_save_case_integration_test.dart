import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase/supabase.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/marketing_case_repository_impl.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';

MarketingCase _deletedPendingCase() {
  final now = DateTime.utc(2026, 8, 8, 16);
  return MarketingCase(
    id: 'mkt-save-case-int',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.ouro,
    lat: -10.1,
    lng: -48.2,
    localizacaoTexto: 'Palmas, TO',
    produtorFazenda: 'Integração Tombstone',
    produtoUtilizado: 'Produto X',
    status: MarketingCaseStatus.published,
    criadoEm: now,
    atualizadoEm: now,
    syncStatus: 'pending_sync',
    ativo: false,
    deletadoEm: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('marketing_save_case_int');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tempDir.path);
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(LocalSessionIdentity.resetForTesting);

  tearDown(LocalSessionIdentity.resetForTesting);

  test(
    'saveCase preserva ativo=false quando resposta HTTP omite o campo ativo',
    () async {
      LocalSessionIdentity.remember('user-integration-1');
      final upserted = _deletedPendingCase();

      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('marketing_cases'));
        final decoded = jsonDecode(request.body);
        final Map<String, dynamic> row = decoded is List
            ? Map<String, dynamic>.from(decoded.first as Map)
            : Map<String, dynamic>.from(decoded as Map);
        expect(row['ativo'], isFalse);
        expect(row['deletado_em'], isNotNull);
        expect(row.containsKey('avaliacoes'), isFalse);
        expect(row.containsKey('title'), isFalse);
        expect(row.containsKey('roi_data'), isFalse);
        expect(
          row.keys.every(MarketingCaseRepositoryImpl.remoteColumns.contains),
          isTrue,
        );

        final responseRow = Map<String, dynamic>.from(row)
          ..remove('ativo')
          ..remove('avaliacoes');

        return http.Response(
          jsonEncode(responseRow),
          200,
          headers: {
            'content-type': 'application/json',
            'content-range': '0-0/1',
          },
          request: request,
        );
      });

      final supabaseClient = SupabaseClient(
        'https://testproject.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSJ9.signature',
        httpClient: mockClient,
      );

      final repo = MarketingCaseRepositoryImpl(supabaseClient);
      final saved = await repo.saveCase(upserted);

      expect(saved.ativo, isFalse);
      expect(saved.deletadoEm, isNotNull);
      expect(saved.syncStatus, 'synced');
    },
  );
}
