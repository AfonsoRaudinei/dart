import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_producer_property_gateway.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_repository.dart';
import 'package:soloforte_app/modules/produtor/data/producer_property_repository.dart';

void main() {
  group('ProducerPropertyRepository', () {
    late _FakePropertyGateway gateway;
    late ProducerPropertyRepository repository;

    setUp(() {
      gateway = _FakePropertyGateway();
      repository = ProducerPropertyRepository(
        propertyGateway: gateway,
        linkRepository: _FakeLinkReader(),
      );
    });

    test('mapeia snapshots neutros sem expor domínio de consultoria', () async {
      final property = await repository.loadOwnProperty();

      expect(property.clientId, 'producer-1');
      expect(property.farms.single.name, 'Retiro');
      expect(property.farms.single.fields.single.hasGeometry, true);
    });

    test('delega comandos de fazenda ao gateway', () async {
      await repository.saveOwnFarm(
        name: 'Retiro',
        city: 'Gurupi',
        state: 'to',
        areaHa: 42,
      );

      expect(gateway.savedFarmName, 'Retiro');
    });

    test('combina propriedade própria e vínculos no dashboard', () async {
      final dashboard = await repository.loadDashboard();

      expect(dashboard.ownProperty.clientId, 'producer-1');
      expect(dashboard.linkedClients, isEmpty);
    });
  });
}

class _FakePropertyGateway implements IProducerPropertyGateway {
  String? savedFarmName;

  @override
  Future<ProducerPropertySnapshot> loadOwnProperty() async {
    return const ProducerPropertySnapshot(
      clientId: 'producer-1',
      name: 'Produtor Teste',
      email: 'produtor@soloforte.app',
      farms: [
        ProducerFarmSnapshot(
          id: 'farm-1',
          name: 'Retiro',
          city: 'Gurupi',
          state: 'TO',
          areaHa: 42,
          fields: [
            ProducerFieldSnapshot(
              id: 'field-1',
              name: 'Talhão 1',
              areaHa: 12,
              hasGeometry: true,
            ),
          ],
        ),
      ],
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
    savedFarmName = name;
  }

  @override
  Future<void> saveOwnField({
    String? fieldId,
    required String farmId,
    required String name,
    required double areaHa,
  }) async {}

  @override
  Future<void> deleteOwnFarm(String farmId) async {}

  @override
  Future<void> deleteOwnField(String fieldId) async {}
}

class _FakeLinkReader implements ProducerLinkReader {
  @override
  Future<List<ProducerLinkedClient>> loadLinkedConsultantData() async => [];
}
