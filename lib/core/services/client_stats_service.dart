import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/local_session_identity.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Dados agregados de um cliente — usado no Hub do Cliente (WS-4).
/// Imutável, com factory `empty` para estado inicial sem dados.
class ClientStats {
  final int totalVisitas;
  final int totalOcorrencias;
  final int totalDesenhos;
  final int totalEventos;
  final int totalRelatorios; // populado após WS-5 (ADR-017)
  final List<Map<String, Object?>> proximosEventos; // top 3
  final List<Map<String, Object?>> ultimasVisitas; // top 3

  const ClientStats({
    required this.totalVisitas,
    required this.totalOcorrencias,
    required this.totalDesenhos,
    required this.totalEventos,
    required this.totalRelatorios,
    required this.proximosEventos,
    required this.ultimasVisitas,
  });

  static const empty = ClientStats(
    totalVisitas: 0,
    totalOcorrencias: 0,
    totalDesenhos: 0,
    totalEventos: 0,
    totalRelatorios: 0,
    proximosEventos: [],
    ultimasVisitas: [],
  );
}

/// Serviço de agregação para contadores do Hub do Cliente.
/// Infraestrutura pura — zero imports de modules/.
/// Queries raw via DatabaseHelper — equivalente ao DatabaseHelper em core/database/.
/// ADR-015 / WS-8.
class ClientStatsService {
  final Database _db;

  ClientStatsService(this._db);

  Future<ClientStats> getStats(String clienteId) async {
    final userId =
        LocalSessionIdentity.resolveUserId();
    return _db.transaction((txn) async {
      final totalVisitas =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM visit_sessions '
              'WHERE producer_id = ? AND user_id = ?',
              [clienteId, userId],
            ),
          ) ??
          0;

      final totalOcorrencias =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM occurrences o '
              'INNER JOIN visit_sessions v ON o.visit_session_id = v.id '
              'WHERE v.producer_id = ? AND v.user_id = ?',
              [clienteId, userId],
            ),
          ) ??
          0;

      final totalDesenhos =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM drawings '
              'WHERE cliente_id = ? AND user_id = ? AND ativo = 1 AND deleted_at IS NULL',
              [clienteId, userId],
            ),
          ) ??
          0;

      final totalEventos =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM agenda_events '
              'WHERE cliente_id = ? AND user_id = ?',
              [clienteId, userId],
            ),
          ) ??
          0;

      final proximosEventos = await txn.rawQuery(
        'SELECT id, titulo, tipo, data_inicio_planejada '
        'FROM agenda_events '
        'WHERE cliente_id = ? AND user_id = ? AND data_inicio_planejada >= ? '
        'ORDER BY data_inicio_planejada ASC LIMIT 3',
        [clienteId, userId, DateTime.now().toIso8601String()],
      );

      final ultimasVisitas = await txn.rawQuery(
        'SELECT id, start_at_real, duracao_min '
        'FROM visit_sessions '
        'WHERE producer_id = ? AND user_id = ? '
        'ORDER BY start_at_real DESC LIMIT 3',
        [clienteId, userId],
      );

      final totalRelatorios =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM relatorios '
              'WHERE client_id = ? AND agronomist_id = ?',
              [clienteId, userId],
            ),
          ) ??
          0;

      return ClientStats(
        totalVisitas: totalVisitas,
        totalOcorrencias: totalOcorrencias,
        totalDesenhos: totalDesenhos,
        totalEventos: totalEventos,
        totalRelatorios: totalRelatorios,
        proximosEventos: proximosEventos,
        ultimasVisitas: ultimasVisitas,
      );
    });
  }
}

/// Provider Riverpod — ADR-008.
/// Uso: ref.watch(clientStatsProvider(clienteId))
final clientStatsProvider =
    FutureProvider.autoDispose.family<ClientStats, String>(
  (ref, clienteId) async {
    final db = await DatabaseHelper.instance.database;
    return ClientStatsService(db).getStats(clienteId);
  },
);
