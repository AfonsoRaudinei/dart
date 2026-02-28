import '../../domain/models/marketing_pin.dart';

abstract class IMarketingPinRepository {
  /// Busca os pins de marketing ativos no servidor (Supabase).
  Future<List<MarketingPin>> fetchMarketingPins();

  /// Busca os pins de marketing que estão no cache local.
  Future<List<MarketingPin>> getCachedMarketingPins();

  /// Salva a lista de pins no cache local.
  Future<void> saveToCache(List<MarketingPin> pins);

  /// Limpa o cache.
  Future<void> clearCache();
}
