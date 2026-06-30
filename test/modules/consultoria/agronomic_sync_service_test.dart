import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/services/agronomic_sync_service.dart';

void main() {
  group('AgronomicSyncService mappers', () {
    test('clientLocalToRemote envia schema completo e aliases legados', () {
      final payload = AgronomicSyncService.clientLocalToRemote({
        'id': 'client-1',
        'user_id': 'user-1',
        'nome': 'Jose Augusto Miranda',
        'telefone': '63999990000',
        'email': 'jose@example.com',
        'cidade': 'Crixas',
        'uf': 'TO',
        'cpf_cnpj': '12345678901',
        'area_total': 120.5,
        'ativo': 1,
        'created_at': '2026-06-05T10:00:00.000',
        'updated_at': '2026-06-05T10:00:00.000',
        'sync_status': AgronomicSyncService.statusDirty,
      });

      expect(payload['nome'], 'Jose Augusto Miranda');
      expect(payload['name'], 'Jose Augusto Miranda');
      expect(payload['telefone'], '63999990000');
      expect(payload['phone'], '63999990000');
      expect(payload['cidade'], 'Crixas');
      expect(payload['city'], 'Crixas');
      expect(payload['uf'], 'TO');
      expect(payload['state'], 'TO');
      expect(payload['cpf_cnpj'], '12345678901');
      expect(payload['document'], '12345678901');
      expect(payload['area_total'], 120.5);
      expect(payload['area_ha'], 120.5);
      expect(payload.containsKey('sync_status'), isFalse);
    });

    test('clientRemoteToLocal aceita schema remoto legado', () {
      final local = AgronomicSyncService.clientRemoteToLocal({
        'id': 'client-1',
        'user_id': 'user-1',
        'name': 'Jose Augusto Miranda',
        'phone': '63999990000',
        'document': '12345678901',
        'email': 'jose@example.com',
        'city': 'Crixas',
        'state': 'TO',
        'area_ha': 120.5,
        'created_at': '2026-06-05T10:00:00.000',
        'updated_at': '2026-06-05T10:00:00.000',
      });

      expect(local['nome'], 'Jose Augusto Miranda');
      expect(local['telefone'], '63999990000');
      expect(local['documento'], '12345678901');
      expect(local['cpf_cnpj'], '12345678901');
      expect(local['cidade'], 'Crixas');
      expect(local['uf'], 'TO');
      expect(local['area_total'], 120.5);
      expect(local['ativo'], 1);
      expect(local['sync_status'], AgronomicSyncService.statusSynced);
    });

    test('farm e field mapeiam aliases entre SQLite e Supabase', () {
      final farmPayload = AgronomicSyncService.farmLocalToRemote({
        'id': 'farm-1',
        'user_id': 'user-1',
        'cliente_id': 'client-1',
        'nome': 'Fazenda Boa Vista',
        'municipio': 'Crixas',
        'uf': 'TO',
        'area_total': 80.0,
        'created_at': '2026-06-05T10:00:00.000',
        'updated_at': '2026-06-05T10:00:00.000',
      });

      expect(farmPayload['cliente_id'], 'client-1');
      expect(farmPayload['client_id'], 'client-1');
      expect(farmPayload['nome'], 'Fazenda Boa Vista');
      expect(farmPayload['name'], 'Fazenda Boa Vista');
      expect(farmPayload['area_total'], 80.0);
      expect(farmPayload['area_ha'], 80.0);

      final fieldLocal = AgronomicSyncService.fieldRemoteToLocal({
        'id': 'field-1',
        'user_id': 'user-1',
        'farm_id': 'farm-1',
        'name': 'Talhao 1',
        'area_ha': 22.3,
        'geometry': {'type': 'Polygon'},
        'created_at': '2026-06-05T10:00:00.000',
        'updated_at': '2026-06-05T10:00:00.000',
      });

      expect(fieldLocal['fazenda_id'], 'farm-1');
      expect(fieldLocal['nome'], 'Talhao 1');
      expect(fieldLocal['area_produtiva'], 22.3);
      expect(fieldLocal['bordadura_geo'], '{"type":"Polygon"}');
      expect(fieldLocal['sync_status'], AgronomicSyncService.statusSynced);
    });

    test('shouldApplyRemote preserva local dirty mais novo', () {
      final shouldApply = AgronomicSyncService.shouldApplyRemote(
        {
          'updated_at': '2026-06-05T11:00:00.000',
          'sync_status': AgronomicSyncService.statusDirty,
        },
        {
          'updated_at': '2026-06-05T10:00:00.000',
          'sync_status': AgronomicSyncService.statusSynced,
        },
      );

      expect(shouldApply, isFalse);
    });
  });
}
