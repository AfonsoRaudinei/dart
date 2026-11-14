import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final consultorMigration = File(
    'supabase/migrations/20261114163000_producer_occurrence_share_bronze_plan.sql',
  ).readAsStringSync();

  final producerViewMigration = File(
    'supabase/migrations/20261114174500_producer_view_occurrence_bronze_plan.sql',
  ).readAsStringSync();

  final bronzePinMigration = File(
    'supabase/migrations/20261114201500_producer_bronze_pin_consultor_plan.sql',
  ).readAsStringSync();

  test('policy exige consultor Bronze+ no ramo vínculo', () {
    expect(
      consultorMigration,
      contains('consultor_pode_compartilhar_ocorrencias'),
    );
    expect(
      consultorMigration,
      contains('create policy occurrences_select_authorized'),
    );
    expect(consultorMigration, contains('link.share_occurrences'));
    expect(
      consultorMigration,
      contains(
        'consultor_pode_compartilhar_ocorrencias(link.consultor_user_id)',
      ),
    );
  });

  test('RPC retorna client_id elegíveis para o produtor', () {
    expect(
      consultorMigration,
      contains('list_occurrence_share_client_ids_for_producer'),
    );
    expect(consultorMigration, contains('grant execute'));
  });

  test('pin Bronze do produtor exige só consultor Bronze+ no vínculo', () {
    expect(
      bronzePinMigration,
      contains('list_bronze_pin_client_ids_for_producer'),
    );
    expect(
      bronzePinMigration,
      contains(
        'consultor_pode_compartilhar_ocorrencias(link.consultor_user_id)',
      ),
    );
    expect(
      bronzePinMigration,
      isNot(contains('consultor_pode_compartilhar_ocorrencias(auth.uid())')),
    );
  });

  test('migration produtor exige Bronze+ do produtor no RPC e na policy', () {
    expect(
      producerViewMigration,
      contains('consultor_pode_compartilhar_ocorrencias(auth.uid())'),
    );
    expect(
      producerViewMigration,
      contains(
        'consultor_pode_compartilhar_ocorrencias(link.consultor_user_id)',
      ),
    );
    expect(
      producerViewMigration,
      contains('create policy occurrences_select_authorized'),
    );
    expect(
      producerViewMigration,
      contains('list_occurrence_share_client_ids_for_producer'),
    );
  });
}
