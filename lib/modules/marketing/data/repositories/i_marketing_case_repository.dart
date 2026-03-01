import '../../domain/entities/marketing_case.dart';

abstract class IMarketingCaseRepository {
  /// Busca os cases no servidor (Supabase).
  Future<List<MarketingCase>> fetchMarketingCases();

  /// Busca os cases apenas no cache local SQLite.
  Future<List<MarketingCase>> getLocalCases();

  /// Substitui todo o cache SQLite com os novos dados recebidos.
  Future<void> saveToCache(List<MarketingCase> cases);

  /// Salva um único case no SQLite (cache local) sem limpar os demais.
  Future<void> saveSingleToCache(MarketingCase marketingCase);

  /// Envia um case novo ao Supabase. Retorna o case com syncStatus='synced'.
  Future<MarketingCase> saveCase(MarketingCase marketingCase);

  /// Obtem detalhes de um case a partir do cache local.
  Future<MarketingCase> getById(String id);
}
