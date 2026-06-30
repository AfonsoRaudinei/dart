import 'package:soloforte_app/core/contracts/i_producer_property_gateway.dart';
import 'package:soloforte_app/modules/consultoria/clients/data/clients_repository.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProducerPropertyGatewayAdapter implements IProducerPropertyGateway {
  ProducerPropertyGatewayAdapter({
    required SupabaseClient supabase,
    required ClientsRepository clientsRepository,
    required FarmRepository farmRepository,
    required FieldRepository fieldRepository,
    Uuid? uuid,
  }) : _supabase = supabase,
       _clientsRepository = clientsRepository,
       _farmRepository = farmRepository,
       _fieldRepository = fieldRepository,
       _uuid = uuid ?? const Uuid();

  final SupabaseClient _supabase;
  final ClientsRepository _clientsRepository;
  final FarmRepository _farmRepository;
  final FieldRepository _fieldRepository;
  final Uuid _uuid;

  @override
  Future<ProducerPropertySnapshot> loadOwnProperty() async {
    final client = await _ensureOwnClient();
    final farms = await _farmRepository.getFarmsByClientId(client.id);
    final snapshots = <ProducerFarmSnapshot>[];

    for (final farm in farms) {
      final fields = await _fieldRepository.getFieldsByFarmId(farm.id);
      snapshots.add(_farmSnapshot(farm, fields));
    }

    return ProducerPropertySnapshot(
      clientId: client.id,
      name: client.name,
      email: client.email,
      farms: snapshots,
    );
  }

  @override
  Future<void> saveOwnFarm({
    String? farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {
    final client = await _ensureOwnClient();
    await _farmRepository.saveFarm(
      Farm(
        id: farmId ?? _uuid.v4(),
        name: name.trim(),
        city: city.trim(),
        state: state.trim().toUpperCase(),
        totalAreaHa: areaHa,
      ),
      client.id,
    );
  }

  @override
  Future<void> saveOwnField({
    String? fieldId,
    required String farmId,
    required String name,
    required double areaHa,
  }) async {
    final current = fieldId == null
        ? null
        : await _fieldRepository.getFieldById(fieldId);
    await _fieldRepository.saveField(
      Talhao(
        id: fieldId ?? _uuid.v4(),
        name: name.trim(),
        areaHa: areaHa,
        crop: current?.crop ?? '',
        harvest: current?.harvest ?? '',
        geometry: current?.geometry,
        perimeter: current?.perimeter,
        thumbnailPath: current?.thumbnailPath,
        syncStatus: current?.syncStatus,
      ),
      farmId,
    );
  }

  @override
  Future<void> deleteOwnFarm(String farmId) async {
    final fields = await _fieldRepository.getFieldsByFarmId(farmId);
    if (fields.isNotEmpty) {
      throw StateError('Remova os talhões antes de excluir a fazenda.');
    }
    await _farmRepository.deleteFarm(farmId);
  }

  @override
  Future<void> deleteOwnField(String fieldId) =>
      _fieldRepository.deleteField(fieldId);

  Future<Client> _ensureOwnClient() async {
    final user = _currentUser();
    final existing = await _clientsRepository.getClientById(user.id);
    if (existing != null) return existing;

    final now = DateTime.now().toUtc();
    final client = Client(
      id: user.id,
      name: resolveOwnClientName(user),
      phone: '',
      city: '',
      state: '',
      email: user.email,
      observation: 'Cadastro próprio do produtor',
      createdAt: now,
      updatedAt: now,
    );
    await _clientsRepository.saveClient(client);
    return client;
  }

  User _currentUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    return user;
  }

  static String resolveOwnClientName(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] ?? metadata['name'])?.toString();
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if ((user.email ?? '').trim().isNotEmpty) return user.email!.trim();
    return 'Produtor';
  }

  static ProducerFarmSnapshot _farmSnapshot(Farm farm, List<Talhao> fields) {
    return ProducerFarmSnapshot(
      id: farm.id,
      name: farm.name,
      city: farm.city,
      state: farm.state,
      areaHa: farm.totalAreaHa,
      fields: fields
          .map(
            (field) => ProducerFieldSnapshot(
              id: field.id,
              name: field.name,
              areaHa: field.areaHa,
              hasGeometry: field.geometry != null,
            ),
          )
          .toList(growable: false),
    );
  }
}
