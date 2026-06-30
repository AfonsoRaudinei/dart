import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import '../../domain/repositories/i_clients_repository.dart';
import 'clients_repository_adapter.dart';

/// Provider de [IClientsRepository] para o módulo drawing.
///
/// Este é o ÚNICO ponto autorizado a referenciar [ClientsRepository] do módulo
/// consultoria dentro do escopo drawing. Toda a lógica de cruzamento de
/// fronteiras está centralizada aqui, conforme ADR-015.
///
/// O [DrawingController] e [drawingControllerProvider] devem depender apenas
/// desta interface — nunca importar consultoria diretamente.
final drawingClientsRepositoryProvider = Provider<IClientsRepository>((ref) {
  return ClientsRepositoryAdapter(
    ref.read(clientLookupProvider),
    ref.read(iFarmLookupProvider),
  );
});

/// Lista de clientes para uso interno do módulo drawing (ex: DrawingMetadataPanel).
///
/// Substitui o uso direto de [clientsListProvider] de consultoria/.
/// Widgets de drawing DEVEM assistir este provider, nunca o de consultoria.
final drawingClientsListProvider = FutureProvider.autoDispose<List<Client>>((
  ref,
) async {
  final repo = ref.watch(drawingClientsRepositoryProvider);
  return repo.getClients();
});
