import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../consultoria/clients/data/clients_repository.dart';
import '../../consultoria/clients/domain/agronomic_models.dart';
import '../../consultoria/clients/domain/client.dart';
import '../../consultoria/farms/data/repositories/farm_repository.dart';
import '../../consultoria/fields/data/repositories/field_repository.dart';
import 'producer_link_models.dart';
import 'producer_link_repository.dart';

final producerPropertyRepositoryProvider = Provider<ProducerPropertyRepository>(
  (ref) {
    return ProducerPropertyRepository(
      supabase: Supabase.instance.client,
      clientsRepository: ClientsRepository(),
      farmRepository: FarmRepository(),
      fieldRepository: FieldRepository(),
      linkRepository: ref.watch(producerLinkRepositoryProvider),
    );
  },
);

final producerPropertyDashboardProvider =
    FutureProvider.autoDispose<ProducerPropertyDashboard>((ref) async {
      final repo = ref.watch(producerPropertyRepositoryProvider);
      return repo.loadDashboard();
    });

class ProducerPropertyRepository {
  ProducerPropertyRepository({
    required SupabaseClient supabase,
    required ClientsRepository clientsRepository,
    required FarmRepository farmRepository,
    required FieldRepository fieldRepository,
    required ProducerLinkRepository linkRepository,
    Uuid? uuid,
  }) : _supabase = supabase,
       _clientsRepository = clientsRepository,
       _farmRepository = farmRepository,
       _fieldRepository = fieldRepository,
       _linkRepository = linkRepository,
       _uuid = uuid ?? const Uuid();

  final SupabaseClient _supabase;
  final ClientsRepository _clientsRepository;
  final FarmRepository _farmRepository;
  final FieldRepository _fieldRepository;
  final ProducerLinkRepository _linkRepository;
  final Uuid _uuid;

  Future<ProducerPropertyDashboard> loadDashboard() async {
    final ownProperty = await loadOwnProperty();
    final linkedClients = await _linkRepository.loadLinkedConsultantData();
    return ProducerPropertyDashboard(
      ownProperty: ownProperty,
      linkedClients: linkedClients,
    );
  }

  Future<ProducerOwnProperty> loadOwnProperty() async {
    final client = await ensureOwnClient();
    final farms = await _farmRepository.getFarmsByClientId(client.id);
    final ownFarms = <ProducerOwnFarm>[];

    for (final farm in farms) {
      final fields = await _fieldRepository.getFieldsByFarmId(farm.id);
      ownFarms.add(_ownFarmFromDomain(farm, fields));
    }

    return ProducerOwnProperty(
      clientId: client.id,
      name: client.name,
      email: client.email,
      farms: ownFarms,
    );
  }

  Future<Client> ensureOwnClient() async {
    final user = _currentUser();
    final clientId = ownClientIdForUser(user.id);
    final existing = await _clientsRepository.getClientById(clientId);
    if (existing != null) return existing;

    final now = DateTime.now().toUtc();
    final client = Client(
      id: clientId,
      name: ownClientName(user),
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

  Future<void> saveOwnFarm({
    String? farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {
    final client = await ensureOwnClient();
    final farm = Farm(
      id: farmId ?? _uuid.v4(),
      name: name.trim(),
      city: city.trim(),
      state: state.trim().toUpperCase(),
      totalAreaHa: areaHa,
    );
    await _farmRepository.saveFarm(farm, client.id);
  }

  Future<void> saveOwnField({
    String? fieldId,
    required String farmId,
    required String name,
    required double areaHa,
  }) async {
    final currentField = fieldId == null
        ? null
        : await _fieldRepository.getFieldById(fieldId);
    final field = Talhao(
      id: fieldId ?? _uuid.v4(),
      name: name.trim(),
      areaHa: areaHa,
      crop: currentField?.crop ?? '',
      harvest: currentField?.harvest ?? '',
      geometry: currentField?.geometry,
      perimeter: currentField?.perimeter,
      thumbnailPath: currentField?.thumbnailPath,
      syncStatus: currentField?.syncStatus,
    );
    await _fieldRepository.saveField(field, farmId);
  }

  Future<void> deleteOwnFarm(String farmId) async {
    final fields = await _fieldRepository.getFieldsByFarmId(farmId);
    if (fields.isNotEmpty) {
      throw StateError('Remova os talhões antes de excluir a fazenda.');
    }

    await _farmRepository.deleteFarm(farmId);
  }

  Future<void> deleteOwnField(String fieldId) async {
    await _fieldRepository.deleteField(fieldId);
  }

  User _currentUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
    return user;
  }

  static String ownClientIdForUser(String userId) => userId;

  static String ownClientName(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] ?? metadata['name'])?.toString();
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if ((user.email ?? '').trim().isNotEmpty) return user.email!.trim();
    return 'Produtor';
  }

  static ProducerOwnFarm _ownFarmFromDomain(Farm farm, List<Talhao> fields) {
    return ProducerOwnFarm(
      id: farm.id,
      name: farm.name,
      city: farm.city,
      state: farm.state,
      areaHa: farm.totalAreaHa,
      fields: fields
          .map(
            (field) => ProducerOwnField(
              id: field.id,
              name: field.name,
              areaHa: field.areaHa,
              hasGeometry: field.geometry != null,
            ),
          )
          .toList(),
    );
  }
}
