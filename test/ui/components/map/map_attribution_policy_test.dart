import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/map_attribution_policy.dart';

void main() {
  test(
    'kMapAttributionPopupInitialDuration é zero — evita sombra preta na entrada',
    () {
      expect(kMapAttributionPopupInitialDuration, Duration.zero);
    },
  );
}
