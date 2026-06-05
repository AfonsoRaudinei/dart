import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/i_clients_repository.dart';
import '../../infra/clients/i_clients_repository_provider.dart';
import '../../../../core/utils/app_logger.dart';

// =============================================================================
// STATE
// =============================================================================

/// Estado de clientes e fazendas para o módulo drawing.
///
/// Extraído de DrawingController conforme ADR-019.
/// Contém a pré-seleção Map-First (query param clienteId) que antes residia
/// no controller, causando rebuild desnecessário do estado de desenho.
class DrawingClientState {
  final List<Client> clients;
  final List<Farm> farms;

  /// ID pré-selecionado via query param `/map?clienteId=X` (Map-First flow).
  final String? preSelectedClientId;
  final String? preSelectedClientName;

  final bool isLoadingClients;
  final bool isLoadingFarms;

  const DrawingClientState({
    this.clients = const [],
    this.farms = const [],
    this.preSelectedClientId,
    this.preSelectedClientName,
    this.isLoadingClients = false,
    this.isLoadingFarms = false,
  });

  DrawingClientState copyWith({
    List<Client>? clients,
    List<Farm>? farms,
    String? preSelectedClientId,
    String? preSelectedClientName,
    bool clearPreSelected = false,
    bool? isLoadingClients,
    bool? isLoadingFarms,
  }) {
    return DrawingClientState(
      clients: clients ?? this.clients,
      farms: farms ?? this.farms,
      preSelectedClientId: clearPreSelected
          ? null
          : (preSelectedClientId ?? this.preSelectedClientId),
      preSelectedClientName: clearPreSelected
          ? null
          : (preSelectedClientName ?? this.preSelectedClientName),
      isLoadingClients: isLoadingClients ?? this.isLoadingClients,
      isLoadingFarms: isLoadingFarms ?? this.isLoadingFarms,
    );
  }
}

// =============================================================================
// NOTIFIER
// =============================================================================

/// Gerencia carregamento de clientes/fazendas e pré-seleção Map-First.
///
/// Responsabilidades:
/// - Carregar clientes via [IClientsRepository] (ADR-015)
/// - Carregar fazendas de um cliente selecionado
/// - Persistir pré-seleção originada de query param
/// - Criar nova fazenda e recarregar lista
///
/// Não conhece estado de desenho — DrawingController permanece independente.
class DrawingClientNotifier extends Notifier<DrawingClientState> {
  IClientsRepository get _repo => ref.read(drawingClientsRepositoryProvider);

  @override
  DrawingClientState build() => const DrawingClientState();

  // ---------------------------------------------------------------------------
  // CLIENTES
  // ---------------------------------------------------------------------------

  Future<void> loadClients() async {
    state = state.copyWith(isLoadingClients: true);
    try {
      final clients = await _repo.getClients();
      state = state.copyWith(clients: clients, isLoadingClients: false);
    } catch (e) {
      AppLogger.warning(
        'Erro ao carregar clientes',
        tag: 'DrawingClientNotifier',
        error: e,
      );
      state = state.copyWith(isLoadingClients: false);
    }
  }

  // ---------------------------------------------------------------------------
  // FAZENDAS
  // ---------------------------------------------------------------------------

  Future<void> loadFarms(String clientId) async {
    state = state.copyWith(farms: [], isLoadingFarms: true);
    try {
      final farms = await _repo.getFarms(clientId);
      state = state.copyWith(farms: farms, isLoadingFarms: false);
    } catch (e) {
      AppLogger.warning(
        'Erro ao carregar fazendas',
        tag: 'DrawingClientNotifier',
        error: e,
      );
      state = state.copyWith(isLoadingFarms: false);
    }
  }

  Future<void> createFarm(
    String name,
    String clientId,
    String city,
    String farmState,
  ) async {
    try {
      final newFarm = Farm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        city: city,
        state: farmState,
        totalAreaHa: 0.0,
        fields: [],
      );
      await _repo.saveFarm(newFarm, clientId);
      await loadFarms(clientId);
    } catch (e) {
      AppLogger.warning(
        'Erro ao criar fazenda',
        tag: 'DrawingClientNotifier',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PRÉ-SELEÇÃO MAP-FIRST (query param clienteId)
  // ---------------------------------------------------------------------------

  /// Define o cliente pré-selecionado via query param e pré-carrega suas fazendas.
  /// Chamado por PrivateMapScreen ao receber `/map?clienteId=X`.
  void setClienteAtivo(String clientId, {String? clientName}) {
    state = state.copyWith(
      preSelectedClientId: clientId,
      preSelectedClientName: clientName,
    );
    loadFarms(clientId);
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

final drawingClientProvider =
    NotifierProvider<DrawingClientNotifier, DrawingClientState>(
      DrawingClientNotifier.new,
    );
