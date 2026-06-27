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
  final String? preSelectedFarmId;
  final String? preSelectedFarmName;

  final bool isLoadingClients;
  final bool isLoadingFarms;

  const DrawingClientState({
    this.clients = const [],
    this.farms = const [],
    this.preSelectedClientId,
    this.preSelectedClientName,
    this.preSelectedFarmId,
    this.preSelectedFarmName,
    this.isLoadingClients = false,
    this.isLoadingFarms = false,
  });

  DrawingClientState copyWith({
    List<Client>? clients,
    List<Farm>? farms,
    String? preSelectedClientId,
    String? preSelectedClientName,
    String? preSelectedFarmId,
    String? preSelectedFarmName,
    bool clearPreSelected = false,
    bool clearPreSelectedFarm = false,
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
      preSelectedFarmId: clearPreSelected || clearPreSelectedFarm
          ? null
          : (preSelectedFarmId ?? this.preSelectedFarmId),
      preSelectedFarmName: clearPreSelected || clearPreSelectedFarm
          ? null
          : (preSelectedFarmName ?? this.preSelectedFarmName),
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

  Future<Farm?> createFarm(
    String name,
    String clientId,
    String city,
    String farmState,
    double areaHa,
  ) async {
    try {
      final newFarm = Farm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        city: city,
        state: farmState,
        totalAreaHa: areaHa,
        fields: [],
      );
      await _repo.saveFarm(newFarm, clientId);
      await loadFarms(clientId);
      for (final farm in state.farms) {
        if (farm.id == newFarm.id) {
          return farm;
        }
      }
      return newFarm;
    } catch (e) {
      AppLogger.warning(
        'Erro ao criar fazenda',
        tag: 'DrawingClientNotifier',
        error: e,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // PRÉ-SELEÇÃO MAP-FIRST (query param clienteId)
  // ---------------------------------------------------------------------------

  /// Define o cliente pré-selecionado via query param e pré-carrega suas fazendas.
  /// Chamado por PrivateMapScreen ao receber `/map?clienteId=X`.
  void setClienteAtivo(
    String clientId, {
    String? clientName,
    String? farmId,
    String? farmName,
  }) {
    state = state.copyWith(
      preSelectedClientId: clientId,
      preSelectedClientName: clientName,
      preSelectedFarmId: farmId,
      preSelectedFarmName: farmName,
      clearPreSelectedFarm: farmId == null,
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
