import 'package:flutter/foundation.dart';
import '../../domain/entities/marketing_case.dart';
import '../repositories/i_marketing_case_repository.dart';

class MarketingSyncService {
  final IMarketingCaseRepository _repository;
  DateTime? _lastSync;
  final Duration _cacheTTL = const Duration(hours: 1);

  MarketingSyncService(this._repository);

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
      debugPrint('Erro no Sync de MarketingCase, servindo Cache antigo: $e');
      return await _repository.getLocalCases();
    }
  }
}
