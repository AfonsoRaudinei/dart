import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return _db.transaction((txn) async {
      final totalVisitas =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM visit_sessions WHERE producer_id = ?',
              [clienteId],
            ),
          ) ??
          0;

      final totalOcorrencias =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM occurrences o '
              'INNER JOIN visit_sessions v ON o.visit_session_id = v.id '
              'WHERE v.producer_id = ?',
              [clienteId],
            ),
          ) ??
          0;

      final totalDesenhos =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM drawings '
              'WHERE cliente_id = ? AND ativo = 1 AND deleted_at IS NULL',
              [clienteId],
            ),
          ) ??
          0;

      final totalEventos =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM agenda_events WHERE cliente_id = ?',
              [clienteId],
            ),
          ) ??
          0;

      final proximosEventos = await txn.rawQuery(
        'SELECT id, titulo, tipo, data_inicio_planejada '
        'FROM agenda_events '
        'WHERE cliente_id = ? AND data_inicio_planejada >= ? '
        'ORDER BY data_inicio_planejada ASC LIMIT 3',
        [clienteId, DateTime.now().toIso8601String()],
      );

      final ultimasVisitas = await txn.rawQuery(
        'SELECT id, created_at '
        'FROM visit_sessions '
        'WHERE producer_id = ? '
        'ORDER BY created_at DESC LIMIT 3',
        [clienteId],
      );

      return ClientStats(
        totalVisitas: totalVisitas,
        totalOcorrencias: totalOcorrencias,
        totalDesenhos: totalDesenhos,
        totalEventos: totalEventos,
        totalRelatorios: 0, // WS-5 (ADR-017)
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
