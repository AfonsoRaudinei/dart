import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/marketing_case_status.dart';
import '../repositories/i_marketing_case_repository.dart';

class MarketingSyncService {
  final IMarketingCaseRepository _repository;
  final String? Function()? _currentUserId;
  DateTime? _lastSync;
  final Duration _cacheTTL = const Duration(hours: 1);

  MarketingSyncService(
    this._repository, {
    String? Function()? currentUserId,
  }) : _currentUserId = currentUserId;

  String _resolveUserId() {
    final resolveUserId = _currentUserId;
    if (resolveUserId != null) {
      return (resolveUserId() ?? '').trim();
    }
    return LocalSessionIdentity.resolveUserId().trim();
  }

  /// Push de `pending_sync` + pull remoto. Sem JWT é no-op.
  Future<void> syncNow() async {
    final userId = _resolveUserId();
    if (userId.isEmpty) {
      return;
    }

    try {
      await _pushPendingCases();
    } catch (e, st) {
      AppLogger.error('Erro no push de MarketingCase', error: e, stackTrace: st);
    }

    try {
      await getCases(forceSync: true);
    } catch (e, st) {
      AppLogger.error('Erro no pull de MarketingCase', error: e, stackTrace: st);
    }
  }

  Future<void> _pushPendingCases() async {
    final localCases = await _repository.getLocalCases();
    for (final local in localCases) {
      if (!_shouldPush(local)) continue;
      try {
        await _repository.saveCase(local);
      } catch (e, st) {
        AppLogger.error(
          'Falha ao enviar MarketingCase ${local.id}; pendencia local preservada',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  bool _shouldPush(MarketingCase local) {
    if (local.syncStatus != 'pending_sync') return false;
    if (local.status == MarketingCaseStatus.draft) return false;
    return true;
  }

  Future<List<MarketingCase>> getCases({bool forceSync = false}) async {
    if (!forceSync) {
      final localCases = await _repository.getLocalCases();
      if (localCases.isNotEmpty) {
        final now = DateTime.now();
        if (_lastSync != null && now.difference(_lastSync!) < _cacheTTL) {
          return localCases; // TTL ainda valido
        }
      }
    }

    // Tenta Sync Remoto Supabase
    try {
      final remoteCases = await _repository.fetchMarketingCases();
      await _repository.saveToCache(remoteCases);
      _lastSync = DateTime.now();
      return remoteCases;
    } catch (e) {
      AppLogger.error('Erro no Sync de MarketingCase, servindo Cache antigo', error: e);
      return await _repository.getLocalCases();
    }
  }
}
