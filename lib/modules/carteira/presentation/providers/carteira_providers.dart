import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/carteira/data/repositories/carteira_repository_impl.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/cliente_categoria.dart';
import 'package:soloforte_app/modules/carteira/domain/repositories/i_carteira_repository.dart';

final carteiraRepositoryProvider = Provider<ICarteiraRepository>((ref) {
  return CarteiraRepositoryImpl();
});

final categoriasGlobaisProvider = FutureProvider.autoDispose
    .family<List<CategoriaGlobal>, String>((ref, userId) async {
      final repo = ref.watch(carteiraRepositoryProvider);
      return repo.getCategorias(userId);
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
