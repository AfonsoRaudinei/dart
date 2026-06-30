import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/enums/unidade_categoria.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_metas_tab.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/categoria_form_dialog.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/cliente_carteira_card.dart';
import 'package:soloforte_app/modules/carteira/presentation/screens/oportunidades_detalhe_screen.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';

class CarteiraScreen extends ConsumerWidget {
  const CarteiraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carteira'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Clientes'),
              Tab(text: 'Categorias'),
              Tab(text: 'Metas'),
              Tab(text: 'Oportunidades'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ClientesTab(userId: userId),
            _CategoriasTab(userId: userId),
            const CarteiraMetasTab(),
            _OportunidadesTab(userId: userId),
          ],
        ),
      ),
    );
  }
}

class _ClientesTab extends ConsumerWidget {
  const _ClientesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(carteiraClientesProvider);
    final categoriasAsync = ref.watch(categoriasGlobaisProvider(userId));
    final registrosAsync = ref.watch(todosRegistrosProvider(userId));

    if (clientesAsync.isLoading ||
        categoriasAsync.isLoading ||
        registrosAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clientesAsync.hasError ||
        categoriasAsync.hasError ||
        registrosAsync.hasError) {
      return const Center(child: Text('Erro ao carregar carteira.'));
    }

    final clientes = clientesAsync.value ?? const [];
    final categorias = categoriasAsync.value ?? const [];
    final registros = registrosAsync.value ?? const [];

    if (clientes.isEmpty) {
      return const Center(child: Text('Nenhum cliente ativo encontrado.'));
    }

    final percentualPorClienteCategoria = <String, int>{
      for (final r in registros)
        '${r.clienteId}_${r.categoriaId}': r.percentualFechado,
    };

    double mediaCliente(String clienteId) {
      if (categorias.isEmpty) return 0;

      var soma = 0;
      for (final categoria in categorias) {
        soma +=
            percentualPorClienteCategoria['${clienteId}_${categoria.id}'] ?? 0;
      }
      return soma / categorias.length;
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(carteiraClientesProvider);
        ref.invalidate(categoriasGlobaisProvider(userId));
        ref.invalidate(todosRegistrosProvider(userId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: clientes.length,
        itemBuilder: (context, index) {
          final cliente = clientes[index];
          return ClienteCarteiraCard(
            clienteNome: cliente.name,
            mediaPercentual: mediaCliente(cliente.id),
            categoriasAtivas: categorias.length,
            onTap: () => context.go(AppRoutes.carteiraCliente(cliente.id)),
          );
        },
      ),
    );
  }
}

class _CategoriasTab extends ConsumerWidget {
  const _CategoriasTab({required this.userId});

  final String userId;

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null || normalized.length != 6) {
      return const Color(0xFF9CA3AF);
    }
    return Color(0xFF000000 | value);
  }

  Future<void> _criarCategoria(BuildContext context, WidgetRef ref) async {
    final result = await showSoloForteSheet<CategoriaFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) => const CategoriaFormDialog(),
    );
    if (result == null) return;

    final categorias = await ref.read(categoriasGlobaisProvider(userId).future);
    final now = DateTime.now();

    final nova = CategoriaGlobal(
      id: const Uuid().v4(),
      userId: userId,
      nome: result.nome,
      cor: result.corHex,
      ativo: true,
      ordem: categorias.length,
      unidade: UnidadeCategoria.realPorHa,
      valorReferencia: result.valorReal,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(carteiraRepositoryProvider).saveCategoria(nova);
    ref.invalidate(categoriasGlobaisProvider(userId));
  }

  Future<void> _editarCategoria(
    BuildContext context,
    WidgetRef ref,
    CategoriaGlobal categoria,
  ) async {
    final result = await showSoloForteSheet<CategoriaFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) => CategoriaFormDialog(
        title: 'Editar categoria',
        initialNome: categoria.nome,
        initialCorHex: categoria.cor,
        initialValorReal: categoria.valorReferencia ?? categoria.valorReal,
      ),
    );
    if (result == null) return;

    await ref
        .read(carteiraRepositoryProvider)
        .updateCategoria(
          categoria.copyWith(
            nome: result.nome,
            cor: result.corHex,
            unidade: categoria.unidade,
            valorReferencia: result.valorReal,
          ),
        );

    ref.invalidate(categoriasGlobaisProvider(userId));
  }

  Future<void> _desativarCategoria(
    BuildContext context,
    WidgetRef ref,
    CategoriaGlobal categoria,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desativar categoria'),
        content: Text('Deseja desativar "${categoria.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(carteiraRepositoryProvider).desativarCategoria(categoria.id);
    ref.invalidate(categoriasGlobaisProvider(userId));
    ref.invalidate(todosRegistrosProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasGlobaisProvider(userId));
    final valorGrao = ref.watch(valorGraoProvider).valueOrNull ?? 0.0;

    return Stack(
      children: [
        categoriasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Erro ao carregar categorias.')),
          data: (categorias) {
            if (categorias.isEmpty) {
              return const Center(child: Text('Nenhuma categoria ativa.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: kFabSafeArea + 88),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                final custoSacasHa = categoria.custoSacasHa(valorGrao);
                return ListTile(
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: _parseColor(categoria.cor),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoria.nome),
                      if (custoSacasHa != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${custoSacasHa.toStringAsFixed(3)} ${categoria.unidade.label}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _editarCategoria(context, ref, categoria),
                      ),
                      IconButton(
                        tooltip: 'Desativar',
                        icon: const Icon(Icons.block_outlined),
                        onPressed: () =>
                            _desativarCategoria(context, ref, categoria),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: kFabSafeArea + 16,
          child: FloatingActionButton.extended(
            onPressed: () => _criarCategoria(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Categoria'),
            backgroundColor: const Color(0xFF4ADE80),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Aba Oportunidades
// ─────────────────────────────────────────────────────────────

class _OportunidadesTab extends ConsumerWidget {
  const _OportunidadesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(carteiraClientesProvider);

    return clientesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erro ao carregar clientes.')),
      data: (clientes) {
        if (clientes.isEmpty) {
          return const Center(child: Text('Nenhuma oportunidade em aberto 🎯'));
        }
        return _OportunidadesClientesList(clientes: clientes, userId: userId);
      },
    );
  }
}

class _OportunidadesClientesList extends ConsumerWidget {
  const _OportunidadesClientesList({
    required this.clientes,
    required this.userId,
  });

  final List<ClientSummary> clientes;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final porCliente = <ClientSummary, List<OportunidadeCliente>>{};

    for (final cliente in clientes) {
      final lista =
          ref.watch(oportunidadesClienteProvider(cliente.id)).valueOrNull ?? [];
      if (lista.isNotEmpty) porCliente[cliente] = lista;
    }

    final algumCarregando = clientes.any(
      (c) => ref.watch(oportunidadesClienteProvider(c.id)).isLoading,
    );

    if (porCliente.isEmpty) {
      if (algumCarregando) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Nenhuma oportunidade em aberto 🎯'));
    }

    final sorted = porCliente.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        final cliente = entry.key;
        final oportunidades = entry.value;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(
              cliente.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${oportunidades.length} '
              '${oportunidades.length == 1 ? 'categoria em aberto' : 'categorias em aberto'}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OportunidadesDetalheScreen(
                  clienteId: cliente.id,
                  clienteNome: cliente.name,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
