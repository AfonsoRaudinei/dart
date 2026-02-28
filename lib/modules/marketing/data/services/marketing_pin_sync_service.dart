import 'package:flutter/material.dart';
import '../../domain/models/marketing_pin.dart';
import '../repositories/i_marketing_pin_repository.dart';

class MarketingPinSyncService {
  final IMarketingPinRepository _repository;
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(hours: 1);

  MarketingPinSyncService(this._repository);

  Future<List<MarketingPin>> getPins() async {
    // Retorna imediatamente o que tem no cache (se existir)
    // enquanto tenta buscar dados atualizados
    final cached = await _repository.getCachedMarketingPins();

    if (_shouldFetch()) {
      _fetchAndSaveInBackground();
    }

    return cached;
  }

  bool _shouldFetch() {
    if (_lastFetch == null) return true;
    final now = DateTime.now();
    return now.difference(_lastFetch!) > _cacheTtl;
  }

  Future<void> _fetchAndSaveInBackground() async {
    try {
      final freshPins = await _repository.fetchMarketingPins();
      await _repository.clearCache();
      await _repository.saveToCache(freshPins);
      _lastFetch = DateTime.now();
    } catch (e) {
      // Ignorar e manter cache local no caso de erro de rede
      debugPrint('Erro ao sincronizar pins de marketing: $e');
    }
  }
}
