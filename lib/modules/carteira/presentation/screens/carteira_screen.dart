import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/extensions/context_extensions.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_ajuda_card.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_metas_tab.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_module_scaffold.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/cliente_carteira_card.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/oportunidades_chart_card.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/oportunidades_chart_mode_toggle.dart';

class CarteiraScreen extends ConsumerStatefulWidget {
  const CarteiraScreen({super.key});

  @override
  ConsumerState<CarteiraScreen> createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends ConsumerState<CarteiraScreen> {
  @override
  Widget build(BuildContext context) {
    ref.watch(sessionControllerProvider);
    ref.listen<CarteiraSegment>(carteiraSegmentProvider, (previous, next) {
      if (previous != null && previous != next) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
    final userId = LocalSessionIdentity.resolveUserId();
    final segment = ref.watch(carteiraSegmentProvider);

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Entre na sua conta para continuar.')),
      );
    }

    return CarteiraModuleScaffold(
      title: 'Carteira',
      body: _buildSegmentBody(userId, segment),
    );
  }

  Widget _buildSegmentBody(String userId, CarteiraSegment segment) {
    return switch (segment) {
      CarteiraSegment.clientes => _ClientesTab(userId: userId),
      CarteiraSegment.categorias => const CarteiraMetasTab(),
      CarteiraSegment.oportunidades => const _OportunidadesTab(),
    };
  }
}

class _ClientesTab extends ConsumerWidget {
  const _ClientesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(carteiraClientesProvider);
    final categoriasAsync = ref.watch(categoriasGlobaisProvider(userId));
    final registrosAsync = ref.watch(closedPercentTodosProvider(userId));

    if (clientesAsync.isLoading ||
        categoriasAsync.isLoading ||
        registrosAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clientesAsync.hasError ||
        categoriasAsync.hasError ||
        registrosAsync.hasError) {
      return const Center(child: Text('Não conseguimos carregar a carteira. Tente de novo.'));
    }

    final clientes = clientesAsync.value ?? const [];
    final categorias = categoriasAsync.value ?? const [];
    final percentualPorClienteCategoria =
        registrosAsync.value ?? const <String, double>{};

    if (clientes.isEmpty) {
      return const CarteiraEstadoVazio(
        titulo: 'Nenhum produtor por aqui ainda',
        mensagem: 'Cadastre um cliente e ele aparece na Carteira.',
      );
    }

    double mediaCliente(String clienteId) {
      if (categorias.isEmpty) return 0;

      var soma = 0.0;
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
        ref.invalidate(closedPercentTodosProvider(userId));
      },
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: context.fabSafeBottomPadding),
        itemCount: clientes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const CarteiraAjudaCard(segment: CarteiraSegment.clientes);
          }
          final cliente = clientes[index - 1];
          return ClienteCarteiraCard(
            clienteNome: cliente.name,
            mediaPercentual: mediaCliente(cliente.id),
            categoriasAtivas: categorias.length,
            categoriasComLancamento: categorias
                .where(
                  (c) =>
                      (percentualPorClienteCategoria['${cliente.id}_${c.id}'] ??
                          0) >
                      0,
                )
                .length,
            onTap: () => context.push(AppRoutes.carteiraCliente(cliente.id)),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Aba Oportunidades
// ─────────────────────────────────────────────────────────────

class _OportunidadesTab extends ConsumerWidget {
  const _OportunidadesTab();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(oportunidadesCarteiraOverviewProvider);
    final chartMode = ref.watch(oportunidadesChartModeProvider);

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const Center(child: Text('Não conseguimos carregar as oportunidades. Tente de novo.')),
      data: (overview) {
        if (overview.porCliente.isEmpty) {
          return const CarteiraEstadoVazio(
            titulo: 'Nenhuma oportunidade em aberto 🎯',
            mensagem:
                'Ou tudo está 100% fechado, ou ainda não há categorias '
                'ativas. Registre lançamentos na aba Clientes.',
          );
        }

        final slices = overview.slicesFor(chartMode);
        final chartTitle = chartMode == OportunidadesChartMode.categoria
            ? 'Oportunidades por categoria'
            : 'Oportunidades por produtor';

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, context.fabSafeBottomPadding),
          children: [
            const CarteiraAjudaCard(
              segment: CarteiraSegment.oportunidades,
              margin: EdgeInsets.only(bottom: 12),
            ),
            OportunidadesChartModeToggle(
              value: chartMode,
              onChanged: (mode) {
                ref.read(oportunidadesChartModeProvider.notifier).state = mode;
              },
            ),
            const SizedBox(height: 12),
            OportunidadesChartCard(
              slices: slices,
              title: chartTitle,
              totalValue: overview.totalValue,
            ),
            const SizedBox(height: 16),
            OportunidadesChartLegend(slices: slices),
            const SizedBox(height: 8),
            Text(
              'Produtores',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...overview.porCliente.map((resumo) {
              final cliente = resumo.cliente;
              final count = resumo.oportunidades.length;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    cliente.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '$count '
                    '${count == 1 ? 'categoria em aberto' : 'categorias em aberto'}'
                    '${resumo.totalValue > 0 ? ' · ${_currencyFormat.format(resumo.totalValue)}' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(carteiraSegmentProvider.notifier).state =
                        CarteiraSegment.oportunidades;
                    context.push(
                      '${AppRoutes.carteiraOportunidades(cliente.id)}'
                      '?nome=${Uri.encodeComponent(cliente.name)}',
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
