import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/i_clients_repository.dart';
import 'clients_repository_adapter.dart';
import '../../../consultoria/clients/data/clients_repository.dart';

/// Provider de [IClientsRepository] para o módulo drawing.
///
/// Este é o ÚNICO ponto autorizado a referenciar [ClientsRepository] do módulo
/// consultoria dentro do escopo drawing. Toda a lógica de cruzamento de
/// fronteiras está centralizada aqui, conforme ADR-015.
///
/// O [DrawingController] e [drawingControllerProvider] devem depender apenas
/// desta interface — nunca importar consultoria diretamente.
final drawingClientsRepositoryProvider = Provider<IClientsRepository>((ref) {
  return ClientsRepositoryAdapter(ClientsRepository());
});
