import 'package:sqflite/sqflite.dart';

import '../../../core/contracts/i_drawing_field_writer.dart';
import '../../../core/contracts/i_producer_crop_calendar.dart';
import '../../../core/session/local_session_identity.dart';

/// Lê e, na propriedade própria, grava o plantio do talhão do mapa.
///
/// Não importa `drawing/` nem `consultoria/`. A escrita passa por
/// [IDrawingFieldWriter]. ADR-062.
class ProducerCropCalendarAdapter implements IProducerCropCalendar {
  ProducerCropCalendarAdapter({
    required Future<Database> Function() openDatabase,
    required IDrawingFieldWriter fieldWriter,
    String Function()? resolveUserId,
  }) : _openDatabase = openDatabase,
       _fieldWriter = fieldWriter,
       _resolveUserId = resolveUserId ?? LocalSessionIdentity.resolveUserId;

  final Future<Database> Function() _openDatabase;
  final IDrawingFieldWriter _fieldWriter;
  final String Function() _resolveUserId;

  @override
  Future<List<ProducerCropPlanting>> listForProducer() async {
    final userId = _resolveUserId().trim();
    if (userId.isEmpty) return const [];

    final db = await _openDatabase();
    final rows = await db.query(
      'drawings',
      columns: const [
        'id',
        'nome',
        'fazenda_id',
        'cliente_id',
        'cultura',
        'safra',
        'data_plantio',
        'data_emergencia',
        'ciclo_dias',
      ],
      where: 'user_id = ? AND deleted_at IS NULL AND ativo = 1 AND tipo = ?',
      whereArgs: [userId, 'talhao'],
      orderBy: 'nome COLLATE NOCASE',
    );

    final farmNames = await _farmNames(
      db,
      rows.map((row) => row['fazenda_id'] as String?).whereType<String>(),
    );
    final ownClientIds = await _ownClientIds(db, userId);

    return rows
        .map((row) {
          final fieldId = row['id'] as String?;
          if (fieldId == null || fieldId.isEmpty) return null;
          final farmId = _blankToNull(row['fazenda_id'] as String?);
          final name = (row['nome'] as String?)?.trim();
          return ProducerCropPlanting(
            fieldId: fieldId,
            fieldName: name == null || name.isEmpty ? 'Talhão' : name,
            farmName: farmId == null ? '' : (farmNames[farmId] ?? ''),
            cultura: _blankToNull(row['cultura'] as String?),
            safra: _blankToNull(row['safra'] as String?),
            dataPlantio: _blankToNull(row['data_plantio'] as String?),
            dataEmergencia: _blankToNull(row['data_emergencia'] as String?),
            cicloDias: _cicloDias(row['ciclo_dias']),
            canEdit: plantingIsOwn(
              userId: userId,
              clienteId: row['cliente_id'] as String?,
              ownClientIds: ownClientIds,
            ),
          );
        })
        .whereType<ProducerCropPlanting>()
        .toList(growable: false);
  }

  @override
  Future<void> saveOwnPlanting({
    required String fieldId,
    String? dataPlantio,
    String? dataEmergencia,
    String? cicloDias,
  }) async {
    final userId = _resolveUserId().trim();
    if (userId.isEmpty) {
      throw StateError('Usuário não autenticado.');
    }
    final id = fieldId.trim();
    if (id.isEmpty) {
      throw StateError('Talhão não informado.');
    }

    final db = await _openDatabase();
    final rows = await db.query(
      'drawings',
      columns: const ['cliente_id'],
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL AND ativo = 1',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Talhão não encontrado.');
    }
    final ownClientIds = await _ownClientIds(db, userId);
    if (!plantingIsOwn(
      userId: userId,
      clienteId: rows.first['cliente_id'] as String?,
      ownClientIds: ownClientIds,
    )) {
      throw StateError('Plantio do consultor é somente leitura.');
    }

    await _fieldWriter.updateFieldMetadata(
      fieldId: id,
      dataPlantio: _blankToNull(dataPlantio),
      dataEmergencia: _blankToNull(dataEmergencia),
      cicloDias: _blankToNull(cicloDias),
    );
  }

  Future<Map<String, String>> _farmNames(
    Database db,
    Iterable<String> farmIds,
  ) async {
    final ids = farmIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) return const {};

    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.query(
      'farms',
      columns: const ['id', 'nome'],
      where: 'id IN ($placeholders) AND deleted_at IS NULL',
      whereArgs: ids,
    );
    final names = <String, String>{};
    for (final row in rows) {
      final id = row['id'] as String?;
      final name = (row['nome'] as String?)?.trim();
      if (id == null || id.isEmpty || name == null || name.isEmpty) continue;
      names[id] = name;
    }
    return names;
  }

  Future<Set<String>> _ownClientIds(Database db, String userId) async {
    final rows = await db.query(
      'clients',
      columns: const ['id'],
      where:
          'user_id = ? AND deleted_at IS NULL AND (id = ? OR observacoes = ?)',
      whereArgs: [userId, userId, ownProducerClientObservation],
    );
    return rows
        .map((row) => (row['id'] as String?)?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }
}

/// Marca do cadastro criado para a propriedade do produtor.
const ownProducerClientObservation = 'Cadastro próprio do produtor';

/// Talhão próprio: sem cliente, cliente da sessão, ou cadastro próprio.
bool plantingIsOwn({
  required String userId,
  required String? clienteId,
  Set<String> ownClientIds = const {},
}) {
  final client = clienteId?.trim() ?? '';
  if (client.isEmpty || client == userId) return true;
  return ownClientIds.contains(client);
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

int? _cicloDias(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
