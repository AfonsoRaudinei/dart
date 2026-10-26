import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/relatorio_combinado_repository.dart';
import '../models/relatorio_combinado.dart';

part 'relatorio_combinado_providers.g.dart';

/// Repositório SQLite de combinações salvas. Sobrescrevível em teste.
@Riverpod(keepAlive: true)
RelatorioCombinadoRepository relatorioCombinadoRepository(
  RelatorioCombinadoRepositoryRef ref,
) {
  return RelatorioCombinadoRepositoryImpl();
}

/// Combinações vivas do produtor, mais recentes primeiro.
@riverpod
Future<List<RelatorioCombinado>> relatoriosCombinados(
  RelatoriosCombinadosRef ref,
  String clientId,
) {
  final repository = ref.watch(relatorioCombinadoRepositoryProvider);
  return repository.listByClient(clientId);
}
