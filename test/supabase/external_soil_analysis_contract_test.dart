import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/20260621000000_external_soil_analyses.sql',
  ).readAsStringSync();
  final edgeFunction = File(
    'supabase/functions/ingest-soil-analysis/index.ts',
  ).readAsStringSync();

  test(
    'RLS permite owner e somente produtor com vinculo ativo nao expirado',
    () {
      expect(migration, contains('auth.uid() = user_id'));
      expect(migration, contains('link.producer_user_id = auth.uid()'));
      expect(migration, contains("link.status = 'active'"));
      expect(migration, contains('link.expires_at > now()'));
      expect(migration, isNot(contains('occurrences.client_id = auth.uid()')));
    },
  );

  test('RLS de insert update e delete permanece restrita ao owner', () {
    expect(migration, contains('create policy occurrences_insert_owner'));
    expect(migration, contains('create policy occurrences_update_owner'));
    expect(migration, contains('create policy occurrences_delete_owner'));
    expect(
      RegExp(r'with check \(auth\.uid\(\) = user_id\)').allMatches(migration),
      hasLength(greaterThanOrEqualTo(2)),
    );
  });

  test(
    'migration e endpoint definem upsert idempotente por origem e owner',
    () {
      expect(migration, contains('occurrences_external_identity_unique'));
      expect(
        migration,
        contains('unique (external_source, user_id, external_analysis_id)'),
      );
      expect(
        edgeFunction,
        contains("onConflict: 'external_source,user_id,external_analysis_id'"),
      );
      expect(migration, contains('occurrences_keep_newest_external'));
      expect(migration, contains('new.updated_at < old.updated_at'));
      expect(migration, contains('return old;'));
    },
  );

  test('mesma origem pode ser configurada por consultores diferentes', () {
    expect(migration, contains('external_source text not null,'));
    expect(migration, contains('unique (owner_user_id, external_source)'));
    expect(migration, isNot(contains('external_source text not null unique')));
  });

  test('endpoint resolve owner no backend e valida client e coordenadas', () {
    expect(edgeFunction, contains(".select('external_source, owner_user_id')"));
    expect(edgeFunction, contains(".eq('user_id', integration.owner_user_id)"));
    expect(edgeFunction, contains("category: 'amostra_solo'"));
    expect(edgeFunction, contains('zero_coordinates_are_not_allowed'));
    expect(
      edgeFunction,
      contains('analysis_payload: validation.analysisPayload'),
    );
    expect(edgeFunction, isNot(contains('body.user_id')));
  });
}
