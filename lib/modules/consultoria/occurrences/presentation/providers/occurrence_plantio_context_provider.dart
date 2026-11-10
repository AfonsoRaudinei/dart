import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import '../../domain/occurrence.dart';
import '../../domain/occurrence_plantio_context.dart';
import '../controllers/occurrence_controller.dart';

/// Talhão e data da ocorrência (null = agora, na criação).
typedef OccurrencePlantioContextQuery = ({
  String fieldId,
  DateTime? referenceDate,
});

/// Ocorrências de Plantio do talhão, não excluídas.
final occurrencePlantioOccurrencesProvider = FutureProvider.autoDispose
    .family<List<Occurrence>, String>((ref, fieldId) {
      return ref
          .read(occurrenceRepositoryProvider)
          .getPlantioOccurrencesByFieldId(fieldId);
    });

/// Plantio gravado no talhão (`drawings`), do usuário atual.
final occurrenceTalhaoPlantioSnapshotProvider = FutureProvider.autoDispose
    .family<TalhaoPlantioSnapshot?, String>((ref, fieldId) async {
      final userId = LocalSessionIdentity.resolveUserId();
      if (userId.isEmpty || fieldId.trim().isEmpty) return null;

      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'drawings',
        columns: [
          'cultura',
          'material',
          'safra',
          'data_plantio',
          'data_emergencia',
          'ciclo_dias',
        ],
        where: 'user_id = ? AND id = ? AND deleted_at IS NULL AND ativo = 1',
        whereArgs: [userId, fieldId.trim()],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      final row = maps.first;
      return TalhaoPlantioSnapshot(
        cultura: _nonEmptyString(row['cultura']),
        material: _nonEmptyString(row['material']),
        safra: _nonEmptyString(row['safra']),
        dataPlantio: _nonEmptyString(row['data_plantio']),
        dataEmergencia: _nonEmptyString(row['data_emergencia']),
        cicloDias: _cicloDias(row['ciclo_dias']),
      );
    });

/// Plantio vigente do talhão na safra da ocorrência (ADR-059).
/// Falha de leitura → null (o formulário volta ao bloco editável).
final occurrencePlantioContextProvider = FutureProvider.autoDispose
    .family<OccurrencePlantioContext?, OccurrencePlantioContextQuery>((
      ref,
      query,
    ) async {
      final fieldId = query.fieldId.trim();
      if (fieldId.isEmpty) return null;
      try {
        final plantios = await ref.watch(
          occurrencePlantioOccurrencesProvider(fieldId).future,
        );
        final talhao = await ref.watch(
          occurrenceTalhaoPlantioSnapshotProvider(fieldId).future,
        );
        return resolvePlantioContext(
          fieldId: fieldId,
          plantioOccurrences: plantios,
          talhao: talhao,
          referenceDate: query.referenceDate,
        );
      } catch (error) {
        AppLogger.warning(
          'contexto de plantio do talhão não resolvido',
          tag: 'Occurrence',
          error: error,
        );
        return null;
      }
    });

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _cicloDias(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
