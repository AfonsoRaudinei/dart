import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/relatorio_tecnico.dart';
import '../repositories/i_relatorio_repository.dart';
import '../repositories/relatorio_repository_impl.dart';

part 'relatorio_providers.g.dart';

/// Provider concreto SQLite de [IRelatorioRepository] — ADR-009
///
/// Registra [RelatorioRepositoryImpl] como implementação oficial do contrato.
/// Mantido em memória durante todo o ciclo de vida do app ([keepAlive: true]).
///
/// Toda camada de domínio ou apresentação deve assistir a este provider.
///
/// Exemplo de consumo em use case:
/// ```dart
/// final repository = ref.watch(relatorioRepositoryProvider);
/// ```
@Riverpod(keepAlive: true)
IRelatorioRepository relatorioRepository(RelatorioRepositoryRef ref) {
  return RelatorioRepositoryImpl();
}

/// Provider de lista de relatórios por cliente — ADR-008
///
/// Retorna a lista de [RelatorioTecnico] associados a um [clientId].
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final relatorios = ref.watch(relatoriosListProvider(clientId: clientId));
/// ```
@riverpod
Future<List<RelatorioTecnico>> relatoriosList(
  RelatoriosListRef ref, {
  required String clientId,
}) async {
  final repository = ref.watch(relatorioRepositoryProvider);
  return repository.getByClientId(clientId);
}

/// Provider de detalhe de relatório — ADR-008
///
/// Retorna um [RelatorioTecnico] pelo [id], ou [null] se não encontrado.
/// AutoDispose para economizar recursos quando a tela sai de foco.
///
/// Consumo típico:
/// ```dart
/// final relatorio = ref.watch(relatorioDetailProvider(id: id));
/// ```
@riverpod
Future<RelatorioTecnico?> relatorioDetail(
  RelatorioDetailRef ref, {
  required String id,
}) async {
  final repository = ref.watch(relatorioRepositoryProvider);
  return repository.getById(id);
}

@riverpod
class RelatorioNotifier extends _$RelatorioNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> updateRelatorio(RelatorioTecnico relatorio) async {
    final repo = ref.read(relatorioRepositoryProvider);
    await repo.update(relatorio);
    // Invalida a lista para esse cliente específico se tivermos clientId, caso contrário não conseguimos invalidar elegantemente.
    // Mas relatoriosListProvider não é a única forma de obter listas.. vamos invalidar tudo da família para garantir:
    ref.invalidate(relatoriosListProvider); 
    ref.invalidate(relatorioDetailProvider);
  }

  Future<void> softDelete(String id) async {
    final repo = ref.read(relatorioRepositoryProvider);
    await repo.softDelete(id);
    ref.invalidate(relatoriosListProvider);
  }
}
