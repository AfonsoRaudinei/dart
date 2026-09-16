import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_marker.dart';
import 'package:soloforte_app/ui/components/map/occurrence_pins.dart';
import 'package:soloforte_app/ui/components/map/widgets/pin_correction_screen_anchor.dart';
import 'package:soloforte_app/ui/screens/map/providers/pin_position_correction_provider.dart';

void main() {
  group('layoutPinCorrectionOnScreen', () {
    test('occurrence centers pin on screen coordinate', () {
      const screenX = 200.0;
      const screenY = 300.0;
      const size = OccurrencePinGenerator.pinSize;

      final layout = layoutPinCorrectionOnScreen(
        kind: PinCorrectionKind.occurrence,
        screenX: screenX,
        screenY: screenY,
      );

      expect(layout.width, size);
      expect(layout.height, size);
      expect(layout.left, screenX - (size / 2));
      expect(layout.top, screenY - (size / 2));
      expect(layout.left + (layout.width / 2), screenX);
      expect(layout.top + (layout.height / 2), screenY);
    });

    test('marketing anchors bottom tip on screen coordinate', () {
      const screenX = 180.0;
      const screenY = 420.0;
      const tier = PlanoMarketing.prata;
      final width = MarketingCaseMarker.pinWidth(tier);
      final height = MarketingCaseMarker.pinHeight(tier) + 10;

      final layout = layoutPinCorrectionOnScreen(
        kind: PinCorrectionKind.marketing,
        screenX: screenX,
        screenY: screenY,
        marketingTier: tier,
      );

      expect(layout.width, width);
      expect(layout.height, height);
      expect(layout.left, screenX - (width / 2));
      expect(layout.top, screenY - height);
      expect(layout.left + (layout.width / 2), screenX);
      expect(layout.top + layout.height, screenY);
    });
  });
}
