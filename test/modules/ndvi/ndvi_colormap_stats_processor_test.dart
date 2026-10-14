import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/ndvi/data/processing/ndvi_colormap_stats_processor.dart';

void main() {
  test('estimateNdviFromColormapRgb mapeia amarelo para faixa media', () {
    final ndvi = estimateNdviFromColormapRgb(255, 204, 0);
    expect(ndvi, closeTo(0.3, 0.01));
  });

}
