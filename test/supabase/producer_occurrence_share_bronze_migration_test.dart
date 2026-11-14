import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20261114163000_producer_occurrence_share_bronze_plan.sql',
  ).readAsStringSync();

  test('policy exige consultor Bronze+ no ramo vínculo', () {
    expect(migration, contains('consultor_pode_compartilhar_ocorrencias'));
    expect(migration, contains('create policy occurrences_select_authorized'));
    expect(migration, contains('link.share_occurrences'));
    expect(
      migration,
      contains(
        'consultor_pode_compartilhar_ocorrencias(link.consultor_user_id)',
      ),
    );
  });

  test('RPC retorna client_id elegíveis para o produtor', () {
    expect(
      migration,
      contains('list_occurrence_share_client_ids_for_producer'),
    );
    expect(migration, contains('grant execute'));
  });
}