import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_farm_lookup.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/marketing_case_client_id_resolver.dart';
import '../repositories/i_marketing_case_repository.dart';

/// Job idempotente: preenche `client_id` ausente em cases legados (ADR-051).
class MarketingCaseClientIdBackfillService {
  final IClientLookup _clientLookup;
  final IFarmLookup _farmLookup;
  final IMarketingCaseRepository _repository;

  const MarketingCaseClientIdBackfillService({
    required IClientLookup clientLookup,
    required IFarmLookup farmLookup,
    required IMarketingCaseRepository repository,
  })  : _clientLookup = clientLookup,
        _farmLookup = farmLookup,
        _repository = repository;

  Future<List<MarketingCase>> backfillIfNeeded(List<MarketingCase> cases) async {
    if (cases.isEmpty) return cases;

    final before = MarketingCaseClientIdCoverage.audit(
      cases.map((item) => item.clientId),
    );
    if (before.withoutClientId == 0) return cases;

    final clients = await _clientLookup.listAtivos();
    final farmsByClientId = <String, List<FarmSummary>>{};
    for (final client in clients) {
      farmsByClientId[client.id] = await _farmLookup.getFarmsByClient(
        client.id,
      );
    }

    final updated = <MarketingCase>[];
    var filledCount = 0;

    for (final item in cases) {
      final existing = item.clientId?.trim();
      if (existing != null && existing.isNotEmpty) {
        updated.add(item);
        continue;
      }

      final resolved = resolveMarketingCaseClientId(
        produtorFazenda: item.produtorFazenda,
        clients: clients,
        farmsByClientId: farmsByClientId,
      );
      if (resolved == null) {
        updated.add(item);
        continue;
      }

      filledCount++;
      final nextSyncStatus = item.syncStatus == 'synced'
          ? 'pending_sync'
          : item.syncStatus;
      final patched = MarketingCase.fromJson({
        ...item.toJson(),
        'client_id': resolved,
        'sync_status': nextSyncStatus,
        'atualizado_em': DateTime.now().toUtc().toIso8601String(),
      });
      updated.add(patched);
      await _repository.saveSingleToCache(patched);
    }

    if (filledCount > 0) {
      final after = MarketingCaseClientIdCoverage.audit(
        updated.map((item) => item.clientId),
      );
      AppLogger.debug(
        'MarketingCase client_id backfill: ${before.toReportLine('antes')} → '
        '${after.toReportLine('depois')}; preenchidos=$filledCount',
        tag: 'MarketingBackfill',
      );
    }

    return updated;
  }
}

/// Relatório estático para auditoria (tool/tests).
MarketingCaseClientIdCoverage auditMarketingCaseClientIdCoverage(
  Iterable<MarketingCase> cases,
) {
  return MarketingCaseClientIdCoverage.audit(cases.map((item) => item.clientId));
}
