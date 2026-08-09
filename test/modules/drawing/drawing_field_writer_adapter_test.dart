import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/infra/drawing_field_writer_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  late DrawingRepository repository;
  late DrawingFieldWriterAdapter adapter;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('field_writer_adapter_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory' ||
              call.method == 'getApplicationDocumentsPath') {
            return tempDir.path;
          }
          return tempDir.path;
        });
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DrawingLocalIdentityStore.resetEphemeralStateForTest();
    LocalSessionIdentity.resetForTesting();
    await db.delete('drawings');

    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final store = DrawingLocalStore(
      identityStore: DrawingLocalIdentityStore(preferences: prefs),
    );
    repository = DrawingRepository(localStore: store);
    adapter = DrawingFieldWriterAdapter(repository);
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('DrawingFieldWriterAdapter.linkFieldToFarm', () {
    test('preenche fazendaId e clienteId mantendo geometria', () async {
      const fieldId = 'drawing-link-1';
      const clientId = 'client-abc';
      const farmId = 'farm-xyz';
      final feature = _feature(fieldId, clienteId: null, fazendaId: null);

      await repository.saveFeature(feature);

      await adapter.linkFieldToFarm(
        fieldId: fieldId,
        clientId: clientId,
        farmId: farmId,
      );

      final updated = await repository.getFeatureById(fieldId);
      expect(updated, isNotNull);
      expect(updated!.properties.clienteId, clientId);
      expect(updated.properties.fazendaId, farmId);
      expect(updated.properties.syncStatus, SyncStatus.local_only);
      expect(updated.geometry.type, feature.geometry.type);
      expect(
        (updated.geometry as DrawingPolygon).coordinates,
        (feature.geometry as DrawingPolygon).coordinates,
      );
    });

    test('ids vazios lançam ArgumentError', () async {
      expect(
        () => adapter.linkFieldToFarm(
          fieldId: '',
          clientId: 'client-1',
          farmId: 'farm-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => adapter.linkFieldToFarm(
          fieldId: 'field-1',
          clientId: 'client-1',
          farmId: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('feature inexistente lança StateError', () async {
      expect(
        () => adapter.linkFieldToFarm(
          fieldId: 'missing-id',
          clientId: 'client-1',
          farmId: 'farm-1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('feature inativa lança StateError', () async {
      const fieldId = 'drawing-inactive';
      final feature = _feature(fieldId, ativo: false);
      await repository.saveFeature(feature);

      expect(
        () => adapter.linkFieldToFarm(
          fieldId: fieldId,
          clientId: 'client-1',
          farmId: 'farm-1',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

DrawingFeature _feature(
  String id, {
  String? clienteId,
  String? fazendaId,
  bool ativo = true,
  SyncStatus syncStatus = SyncStatus.local_only,
}) {
  return DrawingFeature(
    id: id,
    geometry: DrawingPolygon(
      coordinates: [
        [
          [-48.0, -10.0],
          [-47.99, -10.0],
          [-47.99, -9.99],
          [-48.0, -10.0],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Talhão $id',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      clienteId: clienteId,
      fazendaId: fazendaId,
      areaHa: 1.2,
      versao: 1,
      ativo: ativo,
      createdAt: DateTime.utc(2026, 7, 20, 12),
      updatedAt: DateTime.utc(2026, 7, 20, 12),
      syncStatus: syncStatus,
    ),
  );
}
