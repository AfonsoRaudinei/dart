import 'dart:convert';

import 'package:intl/intl.dart';

import '../../../../core/services/sync_status_contract.dart';

/// Nome da tabela SQLite / espelho Supabase (ADR-052).
const String relatoriosCombinadosTable = 'relatorios_combinados';

/// Título automático no save: `Combinado · dd/MM/yyyy · N relatórios`.
String relatorioCombinadoTitle(DateTime when, int count) {
  final label = DateFormat('dd/MM/yyyy').format(when.toLocal());
  return 'Combinado · $label · $count relatórios';
}

/// Combinação salva de relatórios. O HTML não é congelado — só chaves estáveis.
class RelatorioCombinado {
  final String id;
  final String userId;
  final String clientId;
  final String title;
  final List<String> chapterKeys;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final DateTime? deletedAt;

  const RelatorioCombinado({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.title,
    required this.chapterKeys,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.deletedAt,
  });

  RelatorioCombinado copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? title,
    List<String>? chapterKeys,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return RelatorioCombinado(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      chapterKeys: chapterKeys ?? this.chapterKeys,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'title': title,
      'chapters_json': jsonEncode(chapterKeys),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'sync_status': syncStatus,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }

  factory RelatorioCombinado.fromRow(Map<String, Object?> row) {
    return RelatorioCombinado(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      clientId: row['client_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      chapterKeys: decodeRelatorioCombinadoChapters(row['chapters_json']),
      createdAt:
          _parseDate(row['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          _parseDate(row['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      syncStatus:
          (row['sync_status'] as String?) ?? SyncStatusContract.pendingSync,
      deletedAt: _parseDate(row['deleted_at']),
    );
  }
}

List<String> decodeRelatorioCombinadoChapters(Object? raw) {
  if (raw is List) {
    return raw.map((item) => item.toString()).toList();
  }
  if (raw is String && raw.trim().isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((item) => item.toString()).toList();
    }
  }
  return const [];
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
