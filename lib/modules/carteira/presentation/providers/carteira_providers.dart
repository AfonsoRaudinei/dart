import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_opportunity_lookup.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/modules/carteira/data/opportunity_lookup_impl.dart';
import 'package:soloforte_app/modules/carteira/data/repositories/carteira_repository_impl.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_lancamento.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_meta.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_safra.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_tipo_produto.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/cliente_categoria.dart';
import 'package:soloforte_app/modules/carteira/domain/oportunidades_aggregation.dart';
import 'package:soloforte_app/modules/carteira/domain/repositories/i_carteira_repository.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/oportunidades_chart_mode_toggle.dart';

/// Segmento ativo do módulo Carteira — persiste entre telas do bounded context.
final carteiraSegmentProvider = StateProvider<CarteiraSegment>(
  (ref) => CarteiraSegment.clientes,
);

final carteiraRepositoryProvider = Provider<ICarteiraRepository>((ref) {
  return CarteiraRepositoryImpl();
});

/// ADR-029 — instância de [IOpportunityLookup] para o módulo carteira.
final opportunityLookupProvider = Provider<IOpportunityLookup>((ref) {
  return OpportunityLookupImpl(
    repository: ref.watch(carteiraRepositoryProvider),
    db: DatabaseHelper.instance,
  );
});

/// ADR-029 — oportunidades abertas (via [OpportunitySummary]) de um cliente.
final clientOpportunitiesProvider = FutureProvider.autoDispose
    .family<List<OpportunitySummary>, String>((ref, clientId) async {
      final lookup = ref.watch(opportunityLookupProvider);
      return lookup.getOpenOpportunities(clientId);
    });

/// Modo do gráfico na aba Oportunidades (só UI — não altera cálculos ADR-029).
final oportunidadesChartModeProvider = StateProvider<OportunidadesChartMode>(
  (ref) => OportunidadesChartMode.categoria,
);

/// Resumo da carteira: oportunidades por cliente (lookup ADR-029 sem mudança de fórmula).
class OportunidadesClienteResumo {
  const OportunidadesClienteResumo({
    required this.cliente,
    required this.oportunidades,
    required this.totalValue,
    required this.colorArgb,
  });

  final ClientSummary cliente;
  final List<OpportunitySummary> oportunidades;
  final double totalValue;
  final int colorArgb;
}

class OportunidadesCarteiraOverview {
  const OportunidadesCarteiraOverview({
    required this.porCliente,
    required this.allOpportunities,
  });

  final List<OportunidadesClienteResumo> porCliente;
  final List<OpportunitySummary> allOpportunities;

  double get totalValue => sumOpportunityValues(allOpportunities);

  List<OpportunityChartSlice> slicesFor(OportunidadesChartMode mode) {
    return switch (mode) {
      OportunidadesChartMode.categoria => aggregateOpportunitiesByCategory(
        allOpportunities,
      ),
      OportunidadesChartMode.produtor => aggregateOpportunitiesByProducer(
        porCliente.map(
          (r) => (
            clientId: r.cliente.id,
            clientName: r.cliente.name,
            colorArgb: r.colorArgb,
            total: r.totalValue,
          ),
        ),
      ),
    };
  }
}

const _kProducerPalette = <int>[
  0xFFE53935,
  0xFF43A047,
  0xFF1E88E5,
  0xFFFB8C00,
  0xFF8E24AA,
  0xFF00897B,
  0xFF6D4C41,
  0xFF546E7A,
];

final oportunidadesCarteiraOverviewProvider =
    FutureProvider.autoDispose<OportunidadesCarteiraOverview>((ref) async {
      final clients = await ref.watch(carteiraClientesProvider.future);
      final lookup = ref.watch(opportunityLookupProvider);

      final porCliente = <OportunidadesClienteResumo>[];
      final all = <OpportunitySummary>[];

      for (var i = 0; i < clients.length; i++) {
        final cliente = clients[i];
        final ops = await lookup.getOpenOpportunities(cliente.id);
        if (ops.isEmpty) continue;
        final total = sumOpportunityValues(ops);
        final color = _kProducerPalette[i % _kProducerPalette.length];
        porCliente.add(
          OportunidadesClienteResumo(
            cliente: cliente,
            oportunidades: ops,
            totalValue: total,
            colorArgb: color,
          ),
        );
        all.addAll(ops);
      }

      porCliente.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      return OportunidadesCarteiraOverview(
        porCliente: porCliente,
        allOpportunities: all,
      );
    });

final categoriasGlobaisProvider = FutureProvider.autoDispose
    .family<List<CategoriaGlobal>, String>((ref, userId) async {
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getCategorias(userId);
    });

final tiposProdutoProvider = FutureProvider.autoDispose
    .family<List<CarteiraTipoProduto>, String>((ref, userId) async {
      if (userId.isEmpty) return [];
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getTiposProduto(userId);
    });

final categoriasClienteProvider = FutureProvider.autoDispose
    .family<List<ClienteCategoria>, ({String userId, String clienteId})>((
      ref,
      args,
    ) async {
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getCategoriasDoCliente(args.userId, args.clienteId);
    });

final todosRegistrosProvider = FutureProvider.autoDispose
    .family<List<ClienteCategoria>, String>((ref, userId) async {
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getTodosRegistros(userId);
    });

final carteiraClientesProvider =
    FutureProvider.autoDispose<List<ClientSummary>>((ref) async {
      return ref.watch(clientLookupProvider).listAtivos();
    });

final carteiraClienteByIdProvider = FutureProvider.autoDispose
    .family<ClientSummary?, String>((ref, clienteId) async {
      return ref.watch(clientLookupProvider).findById(clienteId);
    });

String _currentUserId(Ref ref) {
  ref.watch(sessionControllerProvider);
  return LocalSessionIdentity.resolveUserId();
}

final valorGraoProvider = FutureProvider<double>((ref) async {
  final userId = _currentUserId(ref);
  if (userId.isEmpty) return 0.0;
  final repo = ref.watch(carteiraRepositoryProvider);
  return repo.getValorGrao(userId);
});

final safrasProvider = FutureProvider.autoDispose<List<CarteiraSafra>>((
  ref,
) async {
  final userId = _currentUserId(ref);
  if (userId.isEmpty) return [];
  final repo = ref.watch(carteiraRepositoryProvider);
  return repo.getSafras(userId);
});

final safraAtivaProvider = FutureProvider<CarteiraSafra?>((ref) async {
  final userId = _currentUserId(ref);
  if (userId.isEmpty) return null;
  final repo = ref.watch(carteiraRepositoryProvider);
  return repo.getSafraAtiva(userId);
});

final metasSafraAtivaProvider = FutureProvider.autoDispose<List<CarteiraMeta>>((
  ref,
) async {
  final safra = await ref.watch(safraAtivaProvider.future);
  if (safra == null) return [];
  final userId = _currentUserId(ref);
  if (userId.isEmpty) return [];
  final repo = ref.watch(carteiraRepositoryProvider);
  return repo.getMetasBySafra(safra.id, userId);
});

final metaCategoriaProvider = FutureProvider.autoDispose
    .family<CarteiraMeta?, String>((ref, categoriaId) async {
      final metas = await ref.watch(metasSafraAtivaProvider.future);
      try {
        return metas.firstWhere((m) => m.categoriaId == categoriaId);
      } catch (_) {
        return null;
      }
    });

final lancamentosSafraProvider = FutureProvider.autoDispose
    .family<
      List<CarteiraLancamento>,
      ({String? categoriaId, String? clienteId})
    >((ref, args) async {
      final safra = await ref.watch(safraAtivaProvider.future);
      if (safra == null) return [];
      final userId = _currentUserId(ref);
      if (userId.isEmpty) return [];
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getLancamentos(
        userId: userId,
        safraId: safra.id,
        categoriaId: args.categoriaId,
        clienteId: args.clienteId,
      );
    });

final realizadoCategoriaProvider = FutureProvider.autoDispose
    .family<double, String>((ref, categoriaId) async {
      final safra = await ref.watch(safraAtivaProvider.future);
      if (safra == null) return 0.0;
      final userId = _currentUserId(ref);
      if (userId.isEmpty) return 0.0;
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getRealizadoBySafraCategoria(safra.id, categoriaId, userId);
    });

final progressoCategoriaProvider = FutureProvider.autoDispose
    .family<double, String>((ref, categoriaId) async {
      final meta = await ref.watch(metaCategoriaProvider(categoriaId).future);
      if (meta == null || meta.quantidade <= 0) return 0.0;

      final lancamentos = await ref.watch(
        lancamentosSafraProvider((
          categoriaId: categoriaId,
          clienteId: null,
        )).future,
      );

      final somaClosedPercent = lancamentos.fold<double>(
        0.0,
        (sum, lancamento) => sum + lancamento.closedPercent,
      );

      return somaClosedPercent.clamp(0.0, 100.0);
    });

final realizadoClienteCategoriaProvider = FutureProvider.autoDispose
    .family<double, ({String clienteId, String categoriaId})>((
      ref,
      args,
    ) async {
      final safra = await ref.watch(safraAtivaProvider.future);
      if (safra == null) return 0.0;
      final userId = _currentUserId(ref);
      if (userId.isEmpty) return 0.0;
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getRealizadoByClienteCategoriaSafra(
        args.clienteId,
        args.categoriaId,
        safra.id,
        userId,
      );
    });

/// Percentual fechado por cliente+categoria (ADR-029 — soma closed_percent).
final closedPercentClienteCategoriaProvider = FutureProvider.autoDispose
    .family<double, ({String clienteId, String categoriaId})>((
      ref,
      args,
    ) async {
      final userId = _currentUserId(ref);
      if (userId.isEmpty) return 0.0;
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getClosedPercentByClienteCategoria(
        args.clienteId,
        args.categoriaId,
        userId,
      );
    });

class OportunidadeCliente {
  final CategoriaGlobal categoria;
  final double metaQuantidade;
  final double realizado;
  final double progressoPct;

  const OportunidadeCliente({
    required this.categoria,
    required this.metaQuantidade,
    required this.realizado,
    required this.progressoPct,
  });

  bool get isAberta => progressoPct < 100.0;

  double get restante =>
      (metaQuantidade - realizado).clamp(0.0, double.infinity);
}

final oportunidadesClienteProvider = FutureProvider.autoDispose
    .family<List<OportunidadeCliente>, String>((ref, clienteId) async {
      final safra = await ref.watch(safraAtivaProvider.future);
      if (safra == null) return [];
      final userId = _currentUserId(ref);
      if (userId.isEmpty) return [];

      final repo = ref.watch(carteiraRepositoryProvider);
      final categorias = await repo.getCategorias(userId);
      final metas = await repo.getMetasBySafra(safra.id, userId);

      if (metas.isEmpty) return [];

      final oportunidades = <OportunidadeCliente>[];

      for (final meta in metas) {
        final categoria = categorias.firstWhere(
          (c) => c.id == meta.categoriaId,
          orElse: () =>
              throw StateError('Categoria ${meta.categoriaId} não encontrada'),
        );

        if (!categoria.ativo) continue;

        final realizado = await repo.getRealizadoByClienteCategoriaSafra(
          clienteId,
          meta.categoriaId,
          safra.id,
          userId,
        );

        final pct = meta.quantidade > 0
            ? (realizado / meta.quantidade * 100.0).clamp(0.0, 100.0)
            : 0.0;

        oportunidades.add(
          OportunidadeCliente(
            categoria: categoria,
            metaQuantidade: meta.quantidade,
            realizado: realizado,
            progressoPct: pct,
          ),
        );
      }

      oportunidades.sort((a, b) => a.progressoPct.compareTo(b.progressoPct));
      return oportunidades.where((o) => o.isAberta).toList();
    });
