import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Card ROI do Novo Case usa fundo fixo #123D2A fora do Azul — texto deve
/// permanecer claro (Colors.white / 0xCCFFFFFF), não `onSheetPrimary` (preto no Verde).
void main() {
  test('novo_case_resultado_section mantém texto claro no card #123D2A (!isIos)', () {
    const path =
        'lib/modules/marketing/presentation/widgets/novo_case_resultado_section.dart';
    final file = File(path);
    expect(file.existsSync(), isTrue);

    final source = file.readAsStringSync();
    expect(
      source,
      contains('const Color(0xFF123D2A)'),
      reason: 'fundo ROI pinado para tema Verde',
    );
    expect(
      source,
      contains('_roiOnDarkPrimary'),
      reason: 'título/valores claros no card verde escuro',
    );
    expect(
      source,
      contains('_roiOnDarkLabel'),
      reason: 'labels secundários com alpha no card escuro',
    );

    final roiCard = source.split('class _RoiPreviewCard').last.split('class ').first;
    expect(roiCard, isNot(contains('v.onSheetPrimary')));
    expect(roiCard, isNot(contains('Colors.white')));
  });
}
