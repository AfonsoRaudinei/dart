import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/session/local_session_identity.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/sync_status_contract.dart';
import '../domain/occurrence.dart';

class OccurrenceOwnershipPolicy {
  const OccurrenceOwnershipPolicy._();

  static const orphanUserId = '';

  static String resolvePersistedUserId({
    required String? currentUserId,
    String? fallbackOwnerUserId,
  }) {
    final normalizedCurrent = currentUserId?.trim() ?? '';
    if (normalizedCurrent.isNotEmpty) return normalizedCurrent;

    final normalizedFallback = fallbackOwnerUserId?.trim() ?? '';
    if (normalizedFallback.isNotEmpty) return normalizedFallback;

    return orphanUserId;
  }

  static String normalizeSyncStatusForWrite({
    required String persistedUserId,
    required String currentSyncStatus,
  }) {
    return SyncStatusContract.normalize(currentSyncStatus);
  }

  static String buildOwnedOrOrphanWhereClause() {
    return "(user_id = ? OR user_id = '${OccurrenceOwnershipPolicy.orphanUserId}')";
  }

  static List<Object?> buildOwnedOrOrphanWhereArgs(String currentUserId) {
    return [currentUserId];
  }
}

class OccurrenceRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  String _scopedUserId() => LocalSessionIdentity.resolveUserId();

  Future<void> saveOccurrence(Occurrence occurrence) async {
    final db = await _databaseHelper.database;
    final persistedUserId = OccurrenceOwnershipPolicy.resolvePersistedUserId(
      currentUserId: _scopedUserId(),
      fallbackOwnerUserId: occurrence.ownerUserId,
    );
    final map = occurrence
        .copyWith(
          syncStatus: OccurrenceOwnershipPolicy.normalizeSyncStatusForWrite(
            persistedUserId: persistedUserId,
            currentSyncStatus: occurrence.syncStatus,
          ),
        )
        .toMap();
    _logOrphanBootstrapWriteIfNeeded(
      action: 'saveOccurrence',
      persistedUserId: persistedUserId,
      occurrenceId: occurrence.id,
    );
    map['user_id'] = persistedUserId;
    await db.insert(
      'occurrences',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateOccurrence(Occurrence occurrence) async {
    if (occurrence.cachedByUserId != null) {
      throw StateError('Ocorrencia compartilhada e somente leitura.');
    }
    final db = await _databaseHelper.database;
    final persistedUserId = OccurrenceOwnershipPolicy.resolvePersistedUserId(
      currentUserId: _scopedUserId(),
      fallbackOwnerUserId: occurrence.ownerUserId,
    );
    final map = occurrence
        .copyWith(
          updatedAt: DateTime.now(),
          syncStatus: persistedUserId.isEmpty
              ? SyncStatusContract.localOnly
              : SyncStatusContract.pendingSync,
        )
        .toMap();
    _logOrphanBootstrapWriteIfNeeded(
      action: 'updateOccurrence',
      persistedUserId: persistedUserId,
      occurrenceId: occurrence.id,
    );
    map['user_id'] = persistedUserId;
    await db.insert(
      'occurrences',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDeleteOccurrence(String id) async {
    final db = await _databaseHelper.database;
    final currentUserId = _scopedUserId();
    final deletedAt = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'occurrences',
      {
        'sync_status': 'deleted_local',
        'deleted_at': deletedAt,
        'updated_at': deletedAt,
      },
      where:
          'id = ? AND ${OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereClause()}',
      whereArgs: [
        id,
        ...OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs(currentUserId),
      ],
    );
  }

  Future<List<Occurrence>> getOccurrencesByClientId(String clientId) async {
    final normalized = clientId.trim();
    if (normalized.isEmpty) return const [];

    final db = await _databaseHelper.database;
    final currentUserId = _scopedUserId();
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      where:
          'client_id = ? AND '
          '(${OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereClause()} '
          'OR cached_by_user_id = ?) '
          "AND sync_status NOT IN ('deleted', 'deleted_local') "
          'AND deleted_at IS NULL',
      whereArgs: [
        normalized,
        ...OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs(currentUserId),
        currentUserId,
      ],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  /// Ocorrências com pin útil para enquadrar o mapa no produtor (check-in / card).
  ///
  /// Inclui `client_id` direto e pins de sessão de visita sem cliente vinculado.
  Future<List<Occurrence>> getOccurrencesForClientMapFocus(
    String clientId,
  ) async {
    final normalized = clientId.trim();
    if (normalized.isEmpty) return const [];

    final direct = await getOccurrencesByClientId(normalized);
    final fromSessions = await _getOccurrencesByVisitProducerId(normalized);
    if (fromSessions.isEmpty) return direct;

    final merged = <String, Occurrence>{
      for (final occurrence in direct) occurrence.id: occurrence,
    };
    for (final occurrence in fromSessions) {
      merged.putIfAbsent(occurrence.id, () => occurrence);
    }
    return merged.values.toList(growable: false);
  }

  Future<List<Occurrence>> _getOccurrencesByVisitProducerId(
    String producerClientId,
  ) async {
    final db = await _databaseHelper.database;
    final currentUserId = _scopedUserId();
    final ownedClause =
        "(o.user_id = ? OR o.user_id = '${OccurrenceOwnershipPolicy.orphanUserId}')";
    final maps = await db.rawQuery(
      '''
      SELECT o.* FROM occurrences o
      INNER JOIN visit_sessions v ON o.visit_session_id = v.id
      WHERE v.producer_id = ?
        AND (o.client_id IS NULL OR TRIM(o.client_id) = '')
        AND ($ownedClause OR o.cached_by_user_id = ?)
        AND o.sync_status NOT IN ('deleted', 'deleted_local')
        AND o.deleted_at IS NULL
      ORDER BY o.created_at DESC
      ''',
      [
        producerClientId,
        ...OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs(currentUserId),
        currentUserId,
      ],
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<List<Occurrence>> getOccurrencesBySession(String sessionId) async {
    final db = await _databaseHelper.database;
    final currentUserId = _scopedUserId();
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      where:
          'visit_session_id = ? AND '
          '${OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereClause()} '
          "AND sync_status NOT IN ('deleted', 'deleted_local') "
          'AND deleted_at IS NULL',
      whereArgs: [
        sessionId,
        ...OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs(currentUserId),
      ],
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<List<Occurrence>> getAllOccurrences() {
    return getAllAuthorizedOccurrences();
  }

  Future<List<Occurrence>> getAllAuthorizedOccurrences({
    Set<String> authorizedClientIds = const {},
  }) async {
    final db = await _databaseHelper.database;
    final currentUserId = _scopedUserId();
    final placeholders = List.filled(authorizedClientIds.length, '?').join(',');
    final sharedClause = authorizedClientIds.isEmpty
        ? ''
        : ' OR (cached_by_user_id = ? AND client_id IN ($placeholders))';
    final args = <Object?>[
      ...OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs(currentUserId),
      if (authorizedClientIds.isNotEmpty) currentUserId,
      ...authorizedClientIds,
    ];
    final List<Map<String, dynamic>> maps = await db.query(
      'occurrences',
      where:
          '(${OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereClause()}$sharedClause) '
          "AND sync_status NOT IN ('deleted', 'deleted_local') "
          'AND deleted_at IS NULL',
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Occurrence.fromMap(maps[i]));
  }

  Future<Map<String, int>> getStats({DateTime? start, DateTime? end}) async {
    final db = await _databaseHelper.database;
    final currentUserId = _scopedUserId();
    String where =
        'WHERE ${OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereClause()} '
        "AND sync_status NOT IN ('deleted', 'deleted_local') "
        'AND deleted_at IS NULL';
    List<dynamic> args = [
      ...OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs(currentUserId),
    ];

    if (start != null && end != null) {
      final endInclusive = end
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
      where += ' AND created_at BETWEEN ? AND ?';
      args = [
        ...OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs(currentUserId),
        start.toIso8601String(),
        endInclusive.toIso8601String(),
      ];
    }

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM occurrences $where',
      args,
    );
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    final typeResult = await db.rawQuery(
      'SELECT type, COUNT(*) as count FROM occurrences $where GROUP BY type',
      args,
    );

    final linkedWhere = '$where AND visit_session_id IS NOT NULL';
    final linkedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM occurrences $linkedWhere',
      args,
    );
    final linked = Sqflite.firstIntValue(linkedResult) ?? 0;

    final Map<String, int> stats = {
      'total': total,
      'linked': linked,
      'avulso': total - linked,
    };
    for (var row in typeResult) {
      stats[row['type'] as String] = row['count'] as int;
    }
    return stats;
  }

  void _logOrphanBootstrapWriteIfNeeded({
    required String action,
    required String persistedUserId,
    required String occurrenceId,
  }) {
    if (persistedUserId.isNotEmpty) return;
    AppLogger.warning(
      'Occurrence bootstrap write without hydrated user. '
      'Saving orphan local record temporarily [action=$action id=$occurrenceId]',
      tag: 'OccurrenceRepository',
    );
  }
}
