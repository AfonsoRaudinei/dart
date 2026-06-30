import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';

/// DTO de cliente usado no módulo drawing.
///
/// Mantém compatibilidade de tipo para UI legada enquanto desacopla
/// drawing/ dos modelos de consultoria/.
class Client extends ClientSummary {
  final String phone;
  final String city;
  final String state;
  final DateTime? createdAt;
  final List<Farm> farms;

  const Client({
    required super.id,
    required super.name,
    super.photoPath,
    this.phone = '',
    this.city = '',
    this.state = '',
    this.createdAt,
    super.active = true,
    this.farms = const [],
  });
}

/// DTO de fazenda usado no módulo drawing.
///
/// Extende FarmSummary para manter compatibilidade com pontos que ainda
/// inicializam city/state/fields no fluxo de criação.
class Farm extends FarmSummary {
  final String city;
  final String state;
  final List<Object> fields;

  const Farm({
    required super.id,
    super.clientId = '',
    required super.name,
    required this.city,
    required this.state,
    double totalAreaHa = 0.0,
    this.fields = const [],
  }) : super(areaHa: totalAreaHa);

  double get totalAreaHa => areaHa ?? 0.0;
}

/// Contrato mínimo de acesso a clientes e fazendas,
/// definido no módulo que consome (drawing), seguindo DIP.
///
/// O [ClientsRepository] do módulo consultoria implementa esta interface.
/// Em testes, basta criar um fake sem tocar no banco.
abstract interface class IClientsRepository {
  Future<List<Client>> getClients();
  Future<List<Farm>> getFarms(String clientId);
  Future<void> saveFarm(Farm farm, String clientId);
}
