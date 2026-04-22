import 'opportunity_summary.dart';

/// Contrato de zona neutra — ADR-029.
/// Provê oportunidades comerciais abertas para um cliente.
abstract interface class IOpportunityLookup {
  /// Retorna oportunidades com [OpportunitySummary.residualPercent] > 0
  /// para o [clientId] informado.
  /// Retorna [] se cliente sem categorias ou tudo já fechado.
  Future<List<OpportunitySummary>> getOpenOpportunities(String clientId);
}
