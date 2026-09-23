import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_actions_sheet.dart';

void main() {
  test('talhaoMapUri inclui ndvi=1 só quando pedido', () {
    final plain = Uri.parse(
      talhaoMapUri(
        modo: 'desenho',
        clientId: 'c1',
        farmId: 'f1',
        drawingId: 'd1',
      ),
    );
    final ndvi = Uri.parse(
      talhaoMapUri(
        modo: 'desenho',
        clientId: 'c1',
        farmId: 'f1',
        drawingId: 'd1',
        ndvi: true,
      ),
    );

    expect(plain.queryParameters.containsKey('ndvi'), isFalse);
    expect(plain.path, '/map');
    expect(ndvi.queryParameters['ndvi'], '1');
    expect(ndvi.queryParameters['drawingId'], 'd1');
    expect(ndvi.queryParameters['modo'], 'desenho');
  });
}
