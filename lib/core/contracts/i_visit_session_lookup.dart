/// DTO mínimo de sessão de visita ativa para contratos entre módulos.
/// Ownership: core/contracts/ — zona neutra, sem imports de modules/.
class VisitSessionSummary {
  final String id;
  final String status;

  const VisitSessionSummary({required this.id, required this.status});

  bool get isActive => status == 'active';
}

/// Contrato de leitura de sessão de visita ativa.
/// Evita acoplamento direto consultoria -> visitas em camadas de presentation.
abstract interface class IVisitSessionLookup {
  /// Retorna a sessão ativa atual, ou null se não houver.
  Future<VisitSessionSummary?> getActiveSession();
}
