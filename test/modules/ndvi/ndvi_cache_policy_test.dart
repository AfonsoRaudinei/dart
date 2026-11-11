import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/ndvi/data/ndvi_cache_policy.dart';

void main() {
  const summary = FieldSummary(
    id: 'F1',
    farmId: 'farm',
    name: 'Talhao',
    bbox: [-47.1, -22.1, -47.0, -22.0],
    geometry: '{"type":"Polygon","coordinates":[]}',
  );

  test('fingerprint com tier standard e refined difere', () {
    final base = ndviOriginFingerprint(summary);
    final standard = ndviOriginFingerprintWithTier(summary, false);
    final refined = ndviOriginFingerprintWithTier(summary, true);

    expect(standard, '$base|standard');
    expect(refined, '$base|refined');
    expect(standard, isNot(refined));
  });
}
