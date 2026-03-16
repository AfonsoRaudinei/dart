import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/categoria_form_dialog.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/cliente_carteira_card.dart';

class CarteiraScreen extends ConsumerStatefulWidget {
  const CarteiraScreen({super.key});

  @override
  ConsumerState<CarteiraScreen> createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends ConsumerState<CarteiraScreen> {
  static const Uuid _uuid = Uuid();

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedCategorias();
    });
  }

  Future<void> _seedCategorias() async {
    final userId = _userId;
    if (userId.isEmpty) return;

    final repo = ref.read(carteiraRepositoryProvider);
    await repo.seedCategoriasIniciais(userId);

    if (!mounted) return;
    ref.invalidate(categoriasGlobaisProvider(userId));
    ref.invalidate(todosRegistrosProvider(userId));
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carteira'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Clientes'),
              Tab(text: 'Categorias'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ClientesTab(userId: userId),
            _CategoriasTab(userId: userId),
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

    if (categorias.isEmpty) {
      return const Center(child: Text('Nenhuma categoria ativa.'));
    }

    final percentualPorClienteCategoria = <String, int>{
      for (final r in registros)
        '${r.clienteId}_${r.categoriaId}': r.percentualFechado,
    };

    double mediaCliente(String clienteId) {
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
    final result = await showDialog<CategoriaFormResult>(
      context: context,
      builder: (_) => const CategoriaFormDialog(),
    );
    if (result == null) return;

    final categorias = await ref.read(categoriasGlobaisProvider(userId).future);
    final now = DateTime.now();

    final nova = CategoriaGlobal(
      id: _CarteiraScreenState._uuid.v4(),
      userId: userId,
      nome: result.nome,
      cor: result.corHex,
      ativo: true,
      ordem: categorias.length,
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
    final result = await showDialog<CategoriaFormResult>(
      context: context,
      builder: (_) => CategoriaFormDialog(
        title: 'Editar categoria',
        initialNome: categoria.nome,
        initialCorHex: categoria.cor,
      ),
    );
    if (result == null) return;

    await ref
        .read(carteiraRepositoryProvider)
        .updateCategoria(
          CategoriaGlobal(
            id: categoria.id,
            userId: categoria.userId,
            nome: result.nome,
            cor: result.corHex,
            ativo: categoria.ativo,
            ordem: categoria.ordem,
            createdAt: categoria.createdAt,
            updatedAt: DateTime.now(),
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
      builder: (_) => AlertDialog(
        title: const Text('Desativar categoria'),
        content: Text('Deseja desativar "${categoria.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
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
                return ListTile(
                  leading: CircleAvatar(
                    radius: 10,
                    backgroundColor: _parseColor(categoria.cor),
                  ),
                  title: Text(categoria.nome),
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
