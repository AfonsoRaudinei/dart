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

  /// Salva um case como rascunho (apenas local, não sincroniza).
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase);

  /// Soft-delete (ADR-048): marca deletado_em, nunca hard delete.
  Future<MarketingCase> softDeleteCase(MarketingCase marketingCase);

  /// Contraparte propõe edição (status pending_approval).
  Future<MarketingCase> proposeEdit({
    required MarketingCase current,
    required MarketingCase proposed,
    required String proposedByUserId,
  });

  /// Owner aprova edição pendente e publica o payload.
  Future<MarketingCase> approvePendingEdit(MarketingCase marketingCase);

  /// Owner rejeita edição pendente e limpa campos pending_*.
  Future<MarketingCase> rejectPendingEdit(MarketingCase marketingCase);

  /// Obtem detalhes de um case a partir do cache local.
  Future<MarketingCase> getById(String id);
}
