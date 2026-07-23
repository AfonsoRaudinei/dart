import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/access/producer_create_context_resolver.dart';
import 'package:soloforte_app/core/contracts/i_producer_property_gateway.dart';

void main() {
  group('ProducerCreateContextResolver', () {
    test('asVisitContext usa fazenda/talhão preferidos', () async {
      final gateway = _FakePropertyGateway(
        const ProducerPropertySnapshot(
          clientId: 'client-own',
          name: 'Produtor Teste',
          email: 'a@b.com',
          farms: [
            ProducerFarmSnapshot(
              id: 'farm-1',
              name: 'Fazenda A',
              city: 'Palmas',
              state: 'TO',
              areaHa: 100,
              fields: [
                ProducerFieldSnapshot(
                  id: 'field-1',
                  name: 'T1',
                  areaHa: 10,
                  hasGeometry: true,
                ),
                ProducerFieldSnapshot(
                  id: 'field-2',
                  name: 'T2',
                  areaHa: 20,
                  hasGeometry: false,
                ),
              ],
            ),
          ],
        ),
      );

      final ctx = await ProducerCreateContextResolver.asVisitContext(
        gateway,
        preferredFarmId: 'farm-1',
        preferredFieldId: 'field-2',
      );

      expect(ctx, isNotNull);
      expect(ctx!.clientId, 'client-own');
      expect(ctx.clientName, 'Produtor Teste');
      expect(ctx.farmId, 'farm-1');
      expect(ctx.fieldId, 'field-2');
      expect(ctx.fieldName, 'T2');
      expect(ctx.city, 'Palmas');
      expect(ctx.state, 'TO');
      expect(ctx.sessionId, 'producer-own');
    });

    test('asClientSummary monta ClientSummary da propriedade', () async {
      final gateway = _FakePropertyGateway(
        const ProducerPropertySnapshot(
          clientId: 'client-own',
          name: 'Produtor Teste',
          email: null,
          farms: [
            ProducerFarmSnapshot(
              id: 'farm-1',
              name: 'Fazenda A',
              city: 'Palmas',
              state: 'TO',
              areaHa: 40,
              fields: [],
            ),
          ],
        ),
      );

      final summary = await ProducerCreateContextResolver.asClientSummary(
        gateway,
      );
      expect(summary, isNotNull);
      expect(summary!.id, 'client-own');
      expect(summary.name, 'Produtor Teste');
      expect(summary.areaTotal, 40);
      expect(summary.active, isTrue);
    });
  });
}

class _FakePropertyGateway implements IProducerPropertyGateway {
  _FakePropertyGateway(this.property);

  final ProducerPropertySnapshot property;

  @override
  Future<ProducerPropertySnapshot> loadOwnProperty() async => property;

  @override
  Future<void> saveOwnFarm({
    String? farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {}

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
