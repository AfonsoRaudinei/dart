import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/i_producer_property_gateway.dart';
import '../../../core/contracts/i_producer_property_gateway_provider.dart';
import 'producer_link_models.dart';
import 'producer_link_repository.dart';

final producerPropertyRepositoryProvider = Provider<ProducerPropertyRepository>(
  (ref) {
    return ProducerPropertyRepository(
      propertyGateway: ref.watch(producerPropertyGatewayProvider),
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
    required IProducerPropertyGateway propertyGateway,
    required ProducerLinkReader linkRepository,
  }) : _propertyGateway = propertyGateway,
       _linkRepository = linkRepository;

  final IProducerPropertyGateway _propertyGateway;
  final ProducerLinkReader _linkRepository;

  Future<ProducerPropertyDashboard> loadDashboard() async {
    final ownProperty = await loadOwnProperty();
    final linkedClients = await _linkRepository.loadLinkedConsultantData();
    return ProducerPropertyDashboard(
      ownProperty: ownProperty,
      linkedClients: linkedClients,
    );
  }

  Future<ProducerOwnProperty> loadOwnProperty() async {
    final property = await _propertyGateway.loadOwnProperty();
    return ProducerOwnProperty(
      clientId: property.clientId,
      name: property.name,
      email: property.email,
      farms: property.farms.map(_farmFromSnapshot).toList(growable: false),
    );
  }

  Future<void> saveOwnFarm({
    String? farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) {
    return _propertyGateway.saveOwnFarm(
      farmId: farmId,
      name: name,
      city: city,
      state: state,
      areaHa: areaHa,
    );
  }

  Future<void> saveOwnField({
    String? fieldId,
    required String farmId,
    required String name,
    required double areaHa,
  }) {
    return _propertyGateway.saveOwnField(
      fieldId: fieldId,
      farmId: farmId,
      name: name,
      areaHa: areaHa,
    );
  }

  Future<void> deleteOwnFarm(String farmId) =>
      _propertyGateway.deleteOwnFarm(farmId);

  Future<void> deleteOwnField(String fieldId) =>
      _propertyGateway.deleteOwnField(fieldId);

  static ProducerOwnFarm _farmFromSnapshot(ProducerFarmSnapshot farm) {
    return ProducerOwnFarm(
      id: farm.id,
      name: farm.name,
      city: farm.city,
      state: farm.state,
      areaHa: farm.areaHa,
      fields: farm.fields
          .map(
            (field) => ProducerOwnField(
              id: field.id,
              name: field.name,
              areaHa: field.areaHa,
              hasGeometry: field.hasGeometry,
            ),
          )
          .toList(growable: false),
    );
  }
}
