import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/network/network_policy.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import '../models/relatorio_status.dart';
import '../models/relatorio_tecnico.dart';
import '../repositories/i_relatorio_repository.dart';

/// Sync push+pull de [RelatorioTecnico] contra `public.relatorios_v2`.
///
/// Pull é **lossy**: o remoto não tem farm_name, period, fotos, talhões
/// nem snapshots — só id, client_id, titulo, descricao, timestamps,
/// created_by, sync_status, deleted_at, visit_session_id, occurrence_ids.
class RelatorioSyncService {
  RelatorioSyncService({
    required IRelatorioRepository repository,
    SupabaseClient? supabase,
    String? Function()? currentUserId,
  }) : _repository = repository,
       _supabase = supabase,
       _currentUserId = currentUserId;

  final IRelatorioRepository _repository;
  final SupabaseClient? _supabase;
  final String? Function()? _currentUserId;

  static const remoteTable = 'relatorios_v2';
  static const _tag = 'RelatorioSync';
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  Future<void> syncNow() async {
    final userId = _resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning(
        'Sync relatorios ignorado: sessao JWT ausente',
        tag: _tag,
      );
      return;
    }
    final client = _supabase;
    if (client == null) {
      AppLogger.warning(
        'Sync relatorios ignorado: cliente remoto ausente',
        tag: _tag,
      );
      return;
    }

    try {
      await _push(client, userId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'RelatorioSync push stage aborted',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _pull(client, userId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'RelatorioSync pull stage aborted',
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
    final pending = await _repository.getPendingSync();
    for (final local in pending) {
      if (!shouldPush(local, userId)) continue;
      try {
        final payload = toRemoteRow(local);
        await NetworkPolicy.withTimeout(
          () => client.from(remoteTable).upsert(payload),
        );
        await _repository.markAsSynced(local.id);
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Falha ao enviar relatorio ${local.id}; pendencia local preservada',
          tag: _tag,
          error: error,
        );
        AppLogger.debug('$stackTrace', tag: _tag);
      }
    }
  }

  Future<void> _pull(SupabaseClient client, String userId) async {
    final remoteRows = await NetworkPolicy.withTimeout(
      () => client
          .from(remoteTable)
          .select()
          .eq('created_by', userId)
          .order('updated_at'),
    );

    for (final raw in remoteRows) {
      Map<String, dynamic>? row;
      try {
        row = Map<String, dynamic>.from(raw as Map);
        final pulled = fromRemoteRow(row);
        final local = await _repository.getById(pulled.id);
        final merged = mergePulled(local: local, pulled: pulled);
        if (identical(merged, local)) continue;
        await _repository.save(merged);
      } catch (error, stackTrace) {
        AppLogger.error(
          'RelatorioSync pull persist failed [id=${row?['id'] ?? '?'}]',
          tag: _tag,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @visibleForTesting
  static bool shouldPush(RelatorioTecnico local, String authUserId) {
    if (authUserId.isEmpty) return false;
    if (local.agronomistId != authUserId) return false;
    return local.syncStatus == RelatorioSyncStatus.pending_sync ||
        local.syncStatus == RelatorioSyncStatus.deleted_local;
  }

  @visibleForTesting
  static bool shouldKeepLocalSnapshots(RelatorioTecnico local) {
    return local.ocorrencias.isNotEmpty ||
        local.talhoes.isNotEmpty ||
        local.fotos.isNotEmpty ||
        local.monitoramentos.isNotEmpty;
  }

  @visibleForTesting
  static bool shouldReplace(RelatorioTecnico local, RelatorioTecnico pulled) {
    return pulled.updatedAt.isAfter(local.updatedAt) &&
        !shouldKeepLocalSnapshots(local);
  }

  /// LWW por `updated_at`. Se o local tem snapshots, não troca por listas
  /// vazias — só título, notas, status e deleted_at.
  @visibleForTesting
  static RelatorioTecnico mergePulled({
    RelatorioTecnico? local,
    required RelatorioTecnico pulled,
  }) {
    if (local == null) return pulled;
    if (!pulled.updatedAt.isAfter(local.updatedAt)) return local;
    if (!shouldKeepLocalSnapshots(local)) return pulled;
    return RelatorioTecnico(
      id: local.id,
      visitSessionId: local.visitSessionId,
      clientId: local.clientId,
      agronomistId: local.agronomistId,
      farmName: local.farmName,
      periodStart: local.periodStart,
      periodEnd: local.periodEnd,
      status: pulled.status,
      syncStatus: RelatorioSyncStatus.synced,
      createdAt: local.createdAt,
      updatedAt: pulled.updatedAt,
      deletedAt: pulled.deletedAt ?? local.deletedAt,
      title: pulled.title,
      customNotes: pulled.customNotes,
      publicacoesRefs: local.publicacoesRefs,
      ocorrencias: local.ocorrencias,
      talhoes: local.talhoes,
      fotos: local.fotos,
      monitoramentos: local.monitoramentos,
    );
  }

  @visibleForTesting
  static Map<String, dynamic> toRemoteRow(RelatorioTecnico local) {
    return {
      'id': local.id,
      'client_id': local.clientId,
      'titulo': _tituloForPush(local),
      'descricao': local.customNotes ?? '',
      'created_by': local.agronomistId,
      'visit_session_id': uuidOrNull(local.visitSessionId),
      'occurrence_ids': jsonEncode(
        local.ocorrencias.map((item) => item.id).toList(),
      ),
      'created_at': local.createdAt.toUtc().toIso8601String(),
      'updated_at': local.updatedAt.toUtc().toIso8601String(),
      'deleted_at': local.deletedAt?.toUtc().toIso8601String(),
      'sync_status': 'synced',
    };
  }

  /// Converte row remota em [RelatorioTecnico] **lossy**.
  @visibleForTesting
  static RelatorioTecnico fromRemoteRow(Map<String, dynamic> row) {
    final createdAt = parseUtc(row['created_at']);
    final updatedAt = row['updated_at'] != null
        ? parseUtc(row['updated_at'])
        : createdAt;
    final deletedAt = row['deleted_at'] != null
        ? parseUtc(row['deleted_at'])
        : null;
    final titulo = (row['titulo'] as String?)?.trim() ?? '';
    final visitSessionId = (row['visit_session_id'] as String?) ?? '';

    return RelatorioTecnico(
      id: row['id'] as String,
      visitSessionId: visitSessionId,
      clientId: (row['client_id'] as String?) ?? '',
      agronomistId: row['created_by'] as String,
      farmName: titulo,
      periodStart: createdAt,
      periodEnd: createdAt,
      status: RelatorioStatus.publicado,
      syncStatus: RelatorioSyncStatus.synced,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      title: titulo,
      customNotes: (row['descricao'] as String?) ?? '',
    );
  }

  @visibleForTesting
  static String? uuidOrNull(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    return _uuidPattern.hasMatch(value) ? value : null;
  }

  @visibleForTesting
  static DateTime parseUtc(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('relatorios_v2 timestamp inválido: $raw');
    }
    return parsed.toUtc();
  }

  static String _tituloForPush(RelatorioTecnico local) {
    final title = local.title?.trim() ?? '';
    if (title.isNotEmpty) return title;
    final farmName = local.farmName.trim();
    if (farmName.isNotEmpty) return farmName;
    return 'Relatório';
  }
}
