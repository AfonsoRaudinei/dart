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
  return ref.watch(reportRepositoryProvider).getAll();
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
  final list = await ref.watch(relatoriosListProvider.future);
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
