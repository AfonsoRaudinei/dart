import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/sync/occurrence_sync_mapper.dart';

void main() {
  test('maps db int to domain string', () {
    expect(OccurrenceSyncMapper.fromDb(0), 'synced');
    expect(OccurrenceSyncMapper.fromDb(1), 'local');
  });

  test('maps domain string to db int', () {
    expect(OccurrenceSyncMapper.toDb('synced'), 0);
    expect(OccurrenceSyncMapper.toDb('local'), 1);
    expect(OccurrenceSyncMapper.toDb('updated'), 1);
  });

  test('detects pending sync status', () {
    expect(OccurrenceSyncMapper.isPending('local'), isTrue);
    expect(OccurrenceSyncMapper.isPending('synced'), isFalse);
  });
}
