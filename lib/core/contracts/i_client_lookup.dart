/// DTO leve de cliente — apenas campos necessários para lookup.
/// Sem Farm, sem ClientCultura, sem campos V15.
/// Ownership: core/contracts/ — zona neutra, sem imports de modules/.
class ClientSummary {
  final String id;
  final String name;
  final String? photoPath;
  final bool active;
  final double areaTotal;

  const ClientSummary({
    required this.id,
    required this.name,
    this.photoPath,
    required this.active,
    this.areaTotal = 0.0,
  });
}

/// Interface de lookup de clientes.
/// Zona neutra em core/contracts/ — acessível por todos os bounded contexts
/// sem violar REGRA 2 (agenda → consultoria e drawing → consultoria são bloqueados).
/// ADR-015.
abstract interface class IClientLookup {
  /// Retorna todos os clientes ativos, ordenados por nome.
  Future<List<ClientSummary>> listAtivos();

  /// Retorna um cliente por ID, ou null se não encontrado.
  Future<ClientSummary?> findById(String id);
}
