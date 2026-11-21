import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_marker.dart';
import 'package:soloforte_app/ui/components/map/widgets/isolated_marker_layers.dart';

class _HiddenMarketingCases extends ShowMarketingCases {
  @override
  bool build() => false;
}

class _VisibleMarketingCases extends ShowMarketingCases {
  @override
  bool build() => true;
}

void main() {
  testWidgets(
    'IsolatedMarketingMarkersLayer não monta marker quando cases estão ocultos',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showMarketingCasesProvider.overrideWith(_HiddenMarketingCases.new),
          ],
          child: const MaterialApp(home: IsolatedMarketingMarkersLayer()),
        ),
      );

      await tester.pump();

      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.byType(MarketingCaseMarker), findsNothing);
    },
  );

  testWidgets(
    'IsolatedMarketingMarkersLayer não monta marker com overlay NDVI ativo',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showMarketingCasesProvider.overrideWith(_VisibleMarketingCases.new),
            mapNdviOverlayFieldIdProvider.overrideWith((ref) => 'field-1'),
          ],
          child: const MaterialApp(home: IsolatedMarketingMarkersLayer()),
        ),
      );

      await tester.pump();

      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.byType(MarketingCaseMarker), findsNothing);
    },
  );
}
