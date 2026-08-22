import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/network/network_policy.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

/// Push + pull das 7 tabelas da carteira (ADR-051).
///
/// Sem JWT: no-op. Com JWT: push (incluindo tombstones) depois pull LWW.
class CarteiraSyncService {
  CarteiraSyncService({
    SupabaseClient? supabase,
    String? Function()? currentUserId,
    DatabaseHelper? dbHelper,
  }) : _supabase = supabase,
       _currentUserId = currentUserId,
       _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final SupabaseClient? _supabase;
  final String? Function()? _currentUserId;
  final DatabaseHelper _dbHelper;

  static const _tag = 'CarteiraSync';

  static const pushPullOrder = <String>[
    'carteira_tipos_produto',
    'carteira_categorias',
    'carteira_config',
    'carteira_safras',
    'carteira_metas',
    'carteira_cliente_categorias',
    'carteira_lancamentos',
  ];

  static const allowedColumns = <String, Set<String>>{
    'carteira_tipos_produto': {
      'id',
      'user_id',
      'codigo',
      'label',
      'converte_sacas_ha',
      'sistema',
      'ativo',
      'ordem',
      'created_at',
      'updated_at',
      'sync_status',
      'deleted_at',
    },
    'carteira_categorias': {
      'id',
      'user_id',
      'nome',
      'cor',
      'ativo',
      'ordem',
      'valor_real',
      'valor_dolar',
      'sacas_por_ha',
      'unidade',
      'valor_referencia',
      'created_at',
      'updated_at',
      'sync_status',
      'deleted_at',
    },
    'carteira_config': {
      'user_id',
      'valor_grao',
      'updated_at',
      'sync_status',
      'deleted_at',
    },
    'carteira_safras': {
      'id',
      'user_id',
      'nome',
      'data_inicio',
      'data_fim',
      'ativa',
      'created_at',
      'updated_at',
      'sync_status',
      'deleted_at',
    },
    'carteira_metas': {
      'id',
      'user_id',
      'safra_id',
      'categoria_id',
      'quantidade',
      'created_at',
      'updated_at',
      'sync_status',
      'deleted_at',
    },
    'carteira_cliente_categorias': {
      'id',
      'user_id',
      'cliente_id',
      'categoria_id',
      'percentual_fechado',
      'observacao',
      'updated_at',
      'sync_status',
      'deleted_at',
    },
    'carteira_lancamentos': {
      'id',
      'user_id',
      'safra_id',
      'categoria_id',
      'cliente_id',
      'quantidade',
      'observacao',
      'data_lancamento',
      'created_at',
      'tipo_fechamento',
      'nome_concorrente',
      'motivo_fechamento',
      'data_fechamento',
      'closed_percent',
      'updated_at',
      'sync_status',
      'deleted_at',
    },
  };

  static const _int01Columns = {
    'converte_sacas_ha',
    'sistema',
    'ativo',
    'ativa',
  };

  Future<void> syncNow() async {
    final userId = _resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning(
        'Sync carteira ignorado: sessao JWT ausente',
        tag: _tag,
      );
      return;
    }
    final client = _supabase;
    if (client == null) {
      AppLogger.warning(
        'Sync carteira ignorado: cliente remoto ausente',
        tag: _tag,
      );
      return;
    }

    try {
      await _push(client, userId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'CarteiraSync push stage aborted',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _pull(client, userId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'CarteiraSync pull stage aborted',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _resolveUserId() {
    final resolveUserId = _currentUserId;
    if (resolveUserId != null) {
      return (resolveUserId() ?? '').trim();
    }
    return _supabase?.auth.currentUser?.id.trim() ?? '';
  }

  Future<void> _push(SupabaseClient client, String userId) async {
    final db = await _dbHelper.database;
    for (final table in pushPullOrder) {
      await _pushTable(client, db, table, userId);
    }
  }

  Future<void> _pushTable(
    SupabaseClient client,
    Database db,
    String table,
    String userId,
  ) async {
    final pending = await db.query(
      table,
      where: 'user_id = ? AND sync_status IN (?, ?)',
      whereArgs: [
        userId,
        SyncStatusContract.pendingSync,
        SyncStatusContract.localOnly,
      ],
    );

    final pk = _primaryKey(table);
    for (final row in pending) {
      try {
        final payload = rowToRemote(table, row);
        await NetworkPolicy.withTimeout(
          () => client.from(table).upsert(payload, onConflict: pk),
        );
        await db.update(
          table,
          {'sync_status': SyncStatusContract.synced},
          where: '$pk = ? AND user_id = ?',
          whereArgs: [row[pk], userId],
        );
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Falha ao enviar $table ${row[pk]}; pendencia local preservada',
          tag: _tag,
          error: error,
        );
        AppLogger.debug('$stackTrace', tag: _tag);
      }
    }
  }

  Future<void> _pull(SupabaseClient client, String userId) async {
    final db = await _dbHelper.database;
    for (final table in pushPullOrder) {
      await _pullTable(client, db, table, userId);
    }
  }

  Future<void> _pullTable(
    SupabaseClient client,
    Database db,
    String table,
    String userId,
  ) async {
    final remoteRows = await NetworkPolicy.withTimeout(
      () => client.from(table).select().eq('user_id', userId),
    );

    final pk = _primaryKey(table);
    for (final raw in remoteRows) {
      Map<String, dynamic>? row;
      try {
        row = Map<String, dynamic>.from(raw as Map);
        final pulled = remoteToLocal(table, row);
        final pkValue = pulled[pk];
        if (pkValue == null) continue;

        final localRows = await db.query(
          table,
          where: '$pk = ? AND user_id = ?',
          whereArgs: [pkValue, userId],
          limit: 1,
        );
        final local = localRows.isEmpty ? null : localRows.first;
        final merged = mergePulled(table, local: local, pulled: pulled);
        if (merged == null) continue;

        if (local != null) {
          await db.update(
            table,
            merged,
            where: '$pk = ? AND user_id = ?',
            whereArgs: [pkValue, userId],
          );
        } else {
          await db.insert(
            table,
            merged,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'CarteiraSync pull persist failed '
          '[table=$table id=${row?[_primaryKey(table)] ?? '?'}]',
          tag: _tag,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  static String _primaryKey(String table) =>
      table == 'carteira_config' ? 'user_id' : 'id';

  /// Copia só colunas do contrato. Nunca inclui campo inventado.
  @visibleForTesting
  static Map<String, dynamic> rowToRemote(
    String table,
    Map<String, Object?> local,
  ) {
    final allowed = allowedColumns[table];
    if (allowed == null) {
      throw ArgumentError.value(table, 'table', 'tabela carteira desconhecida');
    }

    final payload = <String, dynamic>{};
    for (final key in allowed) {
      if (!local.containsKey(key)) continue;
      var value = local[key];
      if (_int01Columns.contains(key)) {
        value = asSqlite01(value);
      } else if (key == 'sync_status') {
        value = SyncStatusContract.synced;
      } else {
        value = asIsoOrSelf(value);
      }
      payload[key] = value;
    }
    return payload;
  }

  @visibleForTesting
  static Map<String, Object?> remoteToLocal(
    String table,
    Map<String, dynamic> remote,
  ) {
    final allowed = allowedColumns[table];
    if (allowed == null) {
      throw ArgumentError.value(table, 'table', 'tabela carteira desconhecida');
    }

    final local = <String, Object?>{};
    for (final key in allowed) {
      if (!remote.containsKey(key) && key != 'sync_status') continue;
      var value = remote[key];
      if (_int01Columns.contains(key)) {
        value = asSqlite01(value);
      } else if (key == 'sync_status') {
        value = SyncStatusContract.synced;
      } else {
        value = asIsoOrSelf(value);
      }
      local[key] = value;
    }
    local['sync_status'] = SyncStatusContract.synced;
    return local;
  }

  /// LWW por `updated_at`. Pendência local não é sobrescrita.
  /// Remoto com `deleted_at` aplica tombstone — nunca hard delete.
  @visibleForTesting
  static bool shouldApplyRemote(
    Map<String, Object?> local,
    Map<String, Object?> pulled,
  ) {
    final localStatus = SyncStatusContract.normalize(
      local['sync_status'] as String?,
    );
    if (localStatus == SyncStatusContract.pendingSync ||
        localStatus == SyncStatusContract.localOnly) {
      return false;
    }

    final localUpdated = parseDate(local['updated_at']) ??
        parseDate(local['created_at']);
    final remoteUpdated = parseDate(pulled['updated_at']) ??
        parseDate(pulled['created_at']);
    if (localUpdated == null || remoteUpdated == null) return true;
    return !remoteUpdated.isBefore(localUpdated);
  }

  /// `null` = manter local (não aplicar). Nunca apaga a linha no pull.
  @visibleForTesting
  static Map<String, Object?>? mergePulled(
    String table, {
    Map<String, Object?>? local,
    required Map<String, Object?> pulled,
  }) {
    if (local == null) {
      return pulled;
    }
    if (!shouldApplyRemote(local, pulled)) {
      return null;
    }

    final merged = Map<String, Object?>.from(pulled);
    merged['sync_status'] = SyncStatusContract.synced;
    if (pulled['deleted_at'] != null) {
      merged['deleted_at'] = asIsoOrSelf(pulled['deleted_at']);
    }
    return merged;
  }

  @visibleForTesting
  static bool shouldHardDeleteOnPull(Map<String, Object?> remote) {
    return false;
  }

  @visibleForTesting
  static int asSqlite01(dynamic value) {
    if (value == true || value == 1 || value == '1' || value == 'true') {
      return 1;
    }
    if (value is num) return value != 0 ? 1 : 0;
    return 0;
  }

  @visibleForTesting
  static Object? asIsoOrSelf(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value;
  }

  @visibleForTesting
  static DateTime? parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
