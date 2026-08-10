import '../../../../../core/contracts/i_visit_session_lookup.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../domain/quick_photo_record.dart';
import '../quick_photo_repository.dart';

/// Estatísticas de cobertura de `client_id` em fotos rápidas.
class QuickPhotoClientIdCoverage {
  final int total;
  final int withClientId;
  final int withoutClientId;

  const QuickPhotoClientIdCoverage({
    required this.total,
    required this.withClientId,
    required this.withoutClientId,
  });

  double get percentWithClientId =>
      total == 0 ? 100 : (withClientId / total) * 100;

  factory QuickPhotoClientIdCoverage.audit(Iterable<String?> clientIds) {
    var withId = 0;
    var withoutId = 0;
    for (final raw in clientIds) {
      if (raw != null && raw.trim().isNotEmpty) {
        withId++;
      } else {
        withoutId++;
      }
    }
    return QuickPhotoClientIdCoverage(
      total: withId + withoutId,
      withClientId: withId,
      withoutClientId: withoutId,
    );
  }

  String toReportLine(String phase) {
    return '$phase: $withClientId/$total com client_id '
        '(${percentWithClientId.toStringAsFixed(1)}%)';
  }
}

/// Job idempotente: preenche `client_id` ausente via sessão de visita (ADR-051).
class QuickPhotoClientIdBackfillService {
  final IQuickPhotoClientIdPatcher _repository;
  final IVisitSessionLookup _visitLookup;

  const QuickPhotoClientIdBackfillService({
    required IQuickPhotoClientIdPatcher repository,
    required IVisitSessionLookup visitLookup,
  })  : _repository = repository,
        _visitLookup = visitLookup;

  Future<List<QuickPhotoRecord>> backfillIfNeeded(
    List<QuickPhotoRecord> photos,
  ) async {
    if (photos.isEmpty) return photos;

    final before = QuickPhotoClientIdCoverage.audit(
      photos.map((item) => item.clientId),
    );
    if (before.withoutClientId == 0) return photos;

    final updated = <QuickPhotoRecord>[];
    var filledCount = 0;

    for (final photo in photos) {
      final existing = photo.clientId?.trim();
      if (existing != null && existing.isNotEmpty) {
        updated.add(photo);
        continue;
      }

      final sessionId = photo.visitSessionId?.trim();
      if (sessionId == null || sessionId.isEmpty) {
        updated.add(photo);
        continue;
      }

      final session = await _visitLookup.findById(sessionId);
      final producerId = session?.producerId.trim();
      if (producerId == null || producerId.isEmpty) {
        updated.add(photo);
        continue;
      }

      final patched = await _repository.patchClientIdIfMissing(
        photoId: photo.id,
        clientId: producerId,
      );
      if (patched != null) {
        filledCount++;
        updated.add(patched);
      } else {
        updated.add(photo);
      }
    }

    if (filledCount > 0) {
      final after = QuickPhotoClientIdCoverage.audit(
        updated.map((item) => item.clientId),
      );
      AppLogger.debug(
        'QuickPhoto client_id backfill: ${before.toReportLine('antes')} → '
        '${after.toReportLine('depois')}; preenchidos=$filledCount',
        tag: 'QuickPhotoBackfill',
      );
    }

    return updated;
  }
}
