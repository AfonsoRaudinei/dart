import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/contracts/i_opportunity_lookup.dart';
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
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  Future<List<OpportunitySummary>> getOpenOpportunities(
    String clientId,
  ) async {
    try {
      final userId = _userId;
      if (userId.isEmpty) return [];

      // 1. Categorias ativas do usuário
      final categorias = await _repository.getCategorias(userId);
      if (categorias.isEmpty) return [];

      final database = await _db.database;

      // 2. area_total do cliente
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

      // 3. Para cada categoria, somar closed_percent dos lançamentos
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
            unit: categoria.unidade.label,
          ),
        );
      }

      // 4. Filtrar apenas oportunidades abertas (residualPercent > 0)
      final open = summaries
          .where((s) => s.residualPercent > 0.0)
          .toList();

      // 5. Ordenar por maior totalOpportunityValue
      open.sort(
        (a, b) =>
            b.totalOpportunityValue.compareTo(a.totalOpportunityValue),
      );

      return open;
    } catch (_) {
      // Nunca propagar exceção para a UI — retornar vazio
      return [];
    }
  }

  /// Converte cor hex (#RRGGBB) para ARGB int.
  int _parseCategoryColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return int.parse('FF$h', radix: 16);
    } catch (_) {
      return 0xFF9CA3AF; // grey fallback
    }
  }
}
