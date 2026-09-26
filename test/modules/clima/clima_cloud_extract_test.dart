import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/domain/clima_cloud_extract.dart';

void main() {
  test('matriz de nuvens tem 20 coeficientes e pinta branco', () {
    expect(climaCloudExtractMatrix, hasLength(20));
    expect(climaCloudExtractMatrix[4], 255);
    expect(climaCloudExtractMatrix[9], 255);
    expect(climaCloudExtractMatrix[14], 255);
  });

  test('chão quente fica transparente e topo frio fica opaco', () {
    expect(climaCloudExtractAlpha(60), 0);
    expect(climaCloudExtractAlpha(climaCloudSurfaceCutoff), 0);
    expect(climaCloudExtractAlpha(climaCloudPeak), 255);
    expect(climaCloudExtractAlpha(255), 255);

    final mid = climaCloudExtractAlpha(
      (climaCloudSurfaceCutoff + climaCloudPeak) ~/ 2,
    );
    expect(mid, greaterThan(80));
    expect(mid, lessThan(180));
  });
}
