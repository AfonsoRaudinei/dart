import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_opportunity_lookup.dart';
import 'package:soloforte_app/core/contracts/opportunity_summary.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/carteira/data/opportunity_lookup_impl.dart';
import 'package:soloforte_app/modules/carteira/data/repositories/carteira_repository_impl.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_lancamento.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_meta.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_safra.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_tipo_produto.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/cliente_categoria.dart';
import 'package:soloforte_app/modules/carteira/domain/repositories/i_carteira_repository.dart';

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

String _currentUserId() => Supabase.instance.client.auth.currentUser?.id ?? '';

final valorGraoProvider = FutureProvider<double>((ref) async {
  final userId = _currentUserId();
  if (userId.isEmpty) return 0.0;
  final repo = ref.watch(carteiraRepositoryProvider);
  return repo.getValorGrao(userId);
});

final safrasProvider = FutureProvider.autoDispose<List<CarteiraSafra>>((
  ref,
) async {
  final userId = _currentUserId();
  if (userId.isEmpty) return [];
  final repo = ref.watch(carteiraRepositoryProvider);
  return repo.getSafras(userId);
});

final safraAtivaProvider = FutureProvider<CarteiraSafra?>((ref) async {
  final userId = _currentUserId();
  if (userId.isEmpty) return null;
  final repo = ref.watch(carteiraRepositoryProvider);
  return repo.getSafraAtiva(userId);
});

final metasSafraAtivaProvider = FutureProvider.autoDispose<List<CarteiraMeta>>((
  ref,
) async {
  final safra = await ref.watch(safraAtivaProvider.future);
  if (safra == null) return [];
  final userId = _currentUserId();
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
      final userId = _currentUserId();
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
      final userId = _currentUserId();
      if (userId.isEmpty) return 0.0;
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getRealizadoBySafraCategoria(safra.id, categoriaId, userId);
    });

final progressoCategoriaProvider = FutureProvider.autoDispose
    .family<double, String>((ref, categoriaId) async {
      final meta = await ref.watch(metaCategoriaProvider(categoriaId).future);
      if (meta == null || meta.quantidade <= 0) return 0.0;

      final lancamentos = await ref.watch(
        lancamentosSafraProvider((categoriaId: categoriaId, clienteId: null))
            .future,
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
      final userId = _currentUserId();
      if (userId.isEmpty) return 0.0;
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getRealizadoByClienteCategoriaSafra(
        args.clienteId,
        args.categoriaId,
        safra.id,
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
      final userId = _currentUserId();
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
