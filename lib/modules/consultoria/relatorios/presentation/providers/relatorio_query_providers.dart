import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/relatorio_status.dart';
import '../../models/relatorio_tecnico.dart';
import '../../providers/relatorio_repository_provider.dart';

part 'relatorio_query_providers.g.dart';

/// Retorna todos os relatórios do agrônomo especificado, ordenados por
/// [updatedAt] DESC, excluindo os logicamente deletados.
///
/// Filtro de status:
///   - `null` → todos (pendente_revisao + publicado + arquivado)
///   - `RelatorioStatus.pendente_revisao` → aba "Meus"
///   - `RelatorioStatus.publicado` → aba "Compartilhados"
@riverpod
Future<List<RelatorioTecnico>> relatoriosByAgronomist(
  RelatoriosByAgronomistRef ref,
  String agronomistId, {
  RelatorioStatus? status,
}) async {
  final repo = ref.watch(relatorioRepositoryProvider);

  final all = await repo.getByAgronomistId(agronomistId);

  final filtered = status == null
      ? all
      : all.where((r) => r.status == status).toList();

  filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return filtered;
}

/// Retorna um único [RelatorioTecnico] pelo [id], ou `null` se não existe.
@riverpod
Future<RelatorioTecnico?> relatorioById(RelatorioByIdRef ref, String id) async {
  final repo = ref.watch(relatorioRepositoryProvider);
  return repo.getById(id);
}
