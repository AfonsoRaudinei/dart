import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20261110203000_producer_link_read_while_active.sql',
  ).readAsStringSync();
  final accept = File(
    'supabase/migrations/20260612000000_producer_client_links.sql',
  ).readAsStringSync();

  test('leitura de ocorrência ativa não exige expires_at', () {
    expect(migration, contains('create policy occurrences_select_authorized'));
    expect(migration, contains("link.status = 'active'"));
    expect(migration, contains('link.producer_user_id = auth.uid()'));
    expect(migration, isNot(contains('link.expires_at')));
  });

  test('aceitar o token pendente continua limitado a 7 dias', () {
    expect(accept, contains('accept_producer_link_token'));
    expect(accept, contains("status = 'pending'"));
    expect(accept, contains('expires_at > now()'));
  });
}
