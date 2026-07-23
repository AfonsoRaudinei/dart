
import 'package:soloforte_app/core/contracts/i_opportunity_lookup.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/carteira/domain/repositories/i_carteira_repository.dart';

/// Implementação de [IOpportunityLookup] para o módulo carteira/.
///
/// Calcula oportunidades abertas por cliente combinando:
/// - categorias ativas do usuário (carteira_categorias)
/// - soma de closed_percent por cliente+categoria (carteira_lancamentos)
/// - area_total do cliente (clients)
///
/// ADR-029 — SoloForte
class OpportunityLookupImpl implements IOpportunityLookup {
  OpportunityLookupImpl({
    required ICarteiraRepository repository,
    required DatabaseHelper db,
  })  : _repository = repository,
        _db = db;

  final ICarteiraRepository _repository;
  final DatabaseHelper _db;

  String get _userId =>
      LocalSessionIdentity.resolveUserId();

  @override
  Future<List<OpportunitySummary>> getOpenOpportunities(
    String clientId,
  ) async {
    try {
      final userId = _userId;
      if (userId.isEmpty) return [];

      final categorias = await _repository.getCategorias(userId);
      if (categorias.isEmpty) return [];

      final database = await _db.database;

      final clientRows = await database.query(
        'clients',
        columns: ['area_total'],
        where: 'id = ?',
        whereArgs: [clientId],
        limit: 1,
      );
      final areaHa = clientRows.isNotEmpty
          ? (clientRows.first['area_total'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      final summaries = <OpportunitySummary>[];

      for (final categoria in categorias) {
        final result = await database.rawQuery(
          'SELECT COALESCE(SUM(closed_percent), 0.0) AS total '
          'FROM carteira_lancamentos '
          'WHERE cliente_id = ? AND categoria_id = ? AND user_id = ?',
          [clientId, categoria.id, userId],
        );
        final rawPct =
            (result.first['total'] as num?)?.toDouble() ?? 0.0;
        final closedPercent = rawPct.clamp(0.0, 100.0);

        summaries.add(
          OpportunitySummary(
            clientId: clientId,
            categoryId: categoria.id,
            categoryName: categoria.nome,
            categoryColor: _parseCategoryColor(categoria.cor),
            referenceValuePerHa: categoria.valorReferencia ?? 0.0,
            closedPercent: closedPercent,
            areaHa: areaHa,
            unit: categoria.unidadeLabel,
          ),
        );
      }

      final open = summaries
          .where((s) => s.residualPercent > 0.0)
          .toList();

      open.sort(
        (a, b) =>
            b.totalOpportunityValue.compareTo(a.totalOpportunityValue),
      );

      return open;
    } catch (_) {
      return [];
    }
  }

  /// Converte cor hex (#RRGGBB) para ARGB int.
  int _parseCategoryColor(String hex) {
    final h = hex.replaceAll('#', '');
    return int.parse('FF$h', radix: 16);
  }
}
