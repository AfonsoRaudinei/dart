import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/marketing_pin.dart';
import 'i_marketing_pin_repository.dart';

class MarketingPinRepositoryImpl implements IMarketingPinRepository {
  final SupabaseClient _supabaseClient;
  Database? _db;

  MarketingPinRepositoryImpl(this._supabaseClient);

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('marketing_pins_cache.db');
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE marketing_pins (
  id $idType,
  nome_produto $textType,
  imagem_url $textType,
  roi_percent $numType,
  plano $textType,
  lat $numType,
  lng $numType,
  ativo $boolType,
  criado_em $textType,
  expira_em TEXT
  )
''');
  }

  @override
  Future<List<MarketingPin>> fetchMarketingPins() async {
    final response = await _supabaseClient
        .from('marketing_pins')
        .select()
        .eq('ativo', true);

    // Filtro adicional no client se expira_em for passado a data
    final now = DateTime.now();

    final pins = (response as List<dynamic>)
        .map((json) => MarketingPin.fromJson(json as Map<String, dynamic>))
        .where((pin) => pin.expiraEm == null || pin.expiraEm!.isAfter(now))
        .toList();

    return pins;
  }

  @override
  Future<List<MarketingPin>> getCachedMarketingPins() async {
    final db = await database;
    final result = await db.query('marketing_pins');

    return result.map((json) {
      // Ajuste para booleanos no SQLite (0 ou 1)
      final mappedJson = Map<String, dynamic>.from(json);
      mappedJson['ativo'] = mappedJson['ativo'] == 1;
      return MarketingPin.fromJson(mappedJson);
    }).toList();
  }

  @override
  Future<void> saveToCache(List<MarketingPin> pins) async {
    final db = await database;

    final batch = db.batch();

    for (var pin in pins) {
      final json = pin.toJson();
      // SQLite store bool as INTEGER (0 ou 1)
      json['ativo'] = pin.ativo ? 1 : 0;

      batch.insert(
        'marketing_pins',
        json,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('marketing_pins');
  }
}
