import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/report_providers.dart';
import '../../../../ui/components/smart_button.dart';

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatoriosAsync = ref.watch(relatoriosFilteredProvider);
    final isSearching = ref
        .watch(relatorioFilterNotifierProvider)
        .search
        .isNotEmpty;

    // We avoid Theme colors from unavailable file, use Theme.of(context) instead
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colorScheme),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (val) => ref
                    .read(relatorioFilterNotifierProvider.notifier)
                    .setSearch(val),
                decoration: InputDecoration(
                  hintText: 'Buscar relatórios...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: relatoriosAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        isSearching
                            ? 'Nenhum relatório encontrado.'
                            : 'Sem relatórios.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final r = list[index];
                      return ListTile(
                        title: Text(r.titulo),
                        subtitle: Text(r.descricao),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erro: $e'),
                      TextButton(
                        onPressed: () => ref.refresh(relatoriosListProvider),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SmartButton(),
              SizedBox(width: 16),
              Text(
                'Relatórios',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
