import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/relatorio.dart';
import '../domain/repositories/i_report_repository.dart';
import '../infra/report_repository_impl.dart';

part 'report_providers.g.dart';

@riverpod
IReportRepository reportRepository(ReportRepositoryRef ref) {
  return ReportRepositoryImpl();
}

@riverpod
Future<List<Relatorio>> relatoriosList(RelatoriosListRef ref) async {
  // ref.read() obrigatório dentro de async — ref.watch() dentro de Future
  // pode causar cancelamento prematuro pelo autoDispose durante animação
  // de navegação, deixando a tela em estado loading permanente (tela cinza).
  return ref.read(reportRepositoryProvider).getAll();
}

class RelatorioFilter {
  final String search;
  const RelatorioFilter({this.search = ''});

  RelatorioFilter copyWith({String? search}) {
    return RelatorioFilter(search: search ?? this.search);
  }
}

@riverpod
class RelatorioFilterNotifier extends _$RelatorioFilterNotifier {
  @override
  RelatorioFilter build() => const RelatorioFilter();

  void setSearch(String query) {
    state = state.copyWith(search: query);
  }
}

@riverpod
Future<List<Relatorio>> relatoriosFiltered(RelatoriosFilteredRef ref) async {
  // ref.read() para o Future — evita race condition com autoDispose
  // ref.watch() no notifier de filtro é seguro (síncrono, não-async)
  final list = await ref.read(relatoriosListProvider.future);
  final filter = ref.watch(relatorioFilterNotifierProvider);

  if (filter.search.isEmpty) return list;

  final query = filter.search.toLowerCase();
  return list
      .where(
        (r) =>
            r.titulo.toLowerCase().contains(query) ||
            r.descricao.toLowerCase().contains(query),
      )
      .toList();
}
