import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/domain/talhao_condicao.dart';
import 'package:soloforte_app/modules/produtor/infra/producer_crop_calendar_adapter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late _FakeFieldWriter writer;
  late ProducerCropCalendarAdapter adapter;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE drawings (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        nome TEXT,
        tipo TEXT,
        fazenda_id TEXT,
        cliente_id TEXT,
        cultura TEXT,
        safra TEXT,
        data_plantio TEXT,
        data_emergencia TEXT,
        ciclo_dias INTEGER,
        deleted_at TEXT,
        ativo INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        observacoes TEXT,
        deleted_at TEXT
      )
    ''');
    await db.insert('clients', {
      'id': 'property-client',
      'user_id': 'produtor',
      'observacoes': ownProducerClientObservation,
    });
    await db.execute('''
      CREATE TABLE farms (
        id TEXT PRIMARY KEY,
        nome TEXT,
        deleted_at TEXT
      )
    ''');
    await db.insert('farms', {'id': 'farm-1', 'nome': 'Fazenda Norte'});
    await db.insert('drawings', {
      'id': 'own-1',
      'user_id': 'produtor',
      'nome': 'Talhão A',
      'tipo': 'talhao',
      'fazenda_id': 'farm-1',
      'cliente_id': 'produtor',
      'cultura': 'Soja',
      'safra': '2026/2027',
      'data_plantio': '2026-01-01',
      'data_emergencia': '2026-01-10',
      'ciclo_dias': 120,
      'ativo': 1,
    });
    await db.insert('drawings', {
      'id': 'own-empty',
      'user_id': 'produtor',
      'nome': 'Talhão B',
      'tipo': 'talhao',
      'fazenda_id': 'farm-1',
      'cliente_id': '',
      'ativo': 1,
    });
    await db.insert('drawings', {
      'id': 'property-1',
      'user_id': 'produtor',
      'nome': 'Talhão da propriedade',
      'tipo': 'talhao',
      'fazenda_id': 'farm-1',
      'cliente_id': 'property-client',
      'ativo': 1,
    });
    await db.insert('drawings', {
      'id': 'linked-1',
      'user_id': 'produtor',
      'nome': 'Talhão do consultor',
      'tipo': 'talhao',
      'fazenda_id': 'farm-1',
      'cliente_id': 'consultor-cliente',
      'cultura': 'Soja',
      'data_plantio': '2026-02-01',
      'ativo': 1,
    });
    await db.insert('drawings', {
      'id': 'zone-1',
      'user_id': 'produtor',
      'nome': 'Zona',
      'tipo': 'zona_manejo',
      'cliente_id': 'produtor',
      'ativo': 1,
    });
    writer = _FakeFieldWriter();
    adapter = ProducerCropCalendarAdapter(
      openDatabase: () async => db,
      fieldWriter: writer,
      resolveUserId: () => 'produtor',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('lista talhão próprio e do consultor, sem zona', () async {
    final plantings = await adapter.listForProducer();
    expect(plantings.map((item) => item.fieldId), [
      'own-1',
      'own-empty',
      'property-1',
      'linked-1',
    ]);

    final own = plantings.first;
    expect(own.farmName, 'Fazenda Norte');
    expect(own.cultura, 'Soja');
    expect(own.safra, '2026/2027');
    expect(own.cicloDias, 120);
    expect(own.canEdit, isTrue);

    expect(plantings[1].canEdit, isTrue);
    expect(plantings[1].dataPlantio, isNull);
    expect(plantings[2].canEdit, isTrue);
    expect(plantings.last.canEdit, isFalse);
  });

  test('grava plantio só no talhão próprio', () async {
    await adapter.saveOwnPlanting(
      fieldId: 'own-empty',
      dataPlantio: '2026-03-01',
      dataEmergencia: '2026-03-08',
      cicloDias: '110',
    );
    expect(writer.fieldId, 'own-empty');
    expect(writer.dataPlantio, '2026-03-01');
    expect(writer.dataEmergencia, '2026-03-08');
    expect(writer.cicloDias, '110');

    await adapter.saveOwnPlanting(
      fieldId: 'property-1',
      dataPlantio: '2026-04-02',
    );
    expect(writer.fieldId, 'property-1');

    expect(
      () => adapter.saveOwnPlanting(
        fieldId: 'linked-1',
        dataPlantio: '2026-04-02',
      ),
      throwsStateError,
    );
    expect(writer.fieldId, 'property-1');
  });

  test('sem usuário não lista plantio', () async {
    final anonymous = ProducerCropCalendarAdapter(
      openDatabase: () async => db,
      fieldWriter: writer,
      resolveUserId: () => '',
    );
    expect(await anonymous.listForProducer(), isEmpty);
  });
}

class _FakeFieldWriter implements IDrawingFieldWriter {
  String? fieldId;
  String? dataPlantio;
  String? dataEmergencia;
  String? cicloDias;

  @override
  Future<void> updateFieldMetadata({
    required String fieldId,
    String? cultura,
    String? material,
    String? safra,
    String? dataPlantio,
    String? dataEmergencia,
    String? cicloDias,
  }) async {
    this.fieldId = fieldId;
    this.dataPlantio = dataPlantio;
    this.dataEmergencia = dataEmergencia;
    this.cicloDias = cicloDias;
  }

  @override
  Future<void> deleteFieldAndRecalculateClientArea({
    required String fieldId,
    required String clientId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> linkFieldToFarm({
    required String fieldId,
    required String clientId,
    required String farmId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateFieldAvaliacao({
    required String fieldId,
    required TalhaoCondicao condicao,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateFieldName({
    required String fieldId,
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> unionDrawingFields({
    required String primaryFieldId,
    required String secondaryFieldId,
    required String clientId,
  }) {
    throw UnimplementedError();
  }
}
