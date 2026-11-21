// Contrato neutro — leitura de [TesteExecucao] vinculada a desenho tipo teste.
// PROIBIDO: importar lib/modules/ neste arquivo.

/// Opção exibida no seletor de marketing (snapshot no case, não leitura ao vivo).
class TesteExecucaoOption {
  const TesteExecucaoOption({
    required this.id,
    required this.drawingId,
    required this.label,
    this.talhao,
    this.fotoUrl,
    this.areaHa,
    this.farmId,
  });

  final String id;
  final String drawingId;
  final String label;
  final String? talhao;
  final String? fotoUrl;
  final double? areaHa;
  final String? farmId;
}

/// Lista execuções de teste filtradas por cliente (e opcionalmente fazenda).
abstract interface class ITesteExecucaoLookup {
  Future<List<TesteExecucaoOption>> listByClient({
    required String clientId,
    String? farmId,
  });
}