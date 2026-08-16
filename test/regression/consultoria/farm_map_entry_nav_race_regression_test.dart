import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Blindagem: Clientes → + Talhão → Desenhar no Mapa → Continuar.
///
/// `Navigator.pop` + `showSoloForteSheet`/`context.go` no mesmo microtask
/// falha de forma intermitente (Navigator locked). O fluxo Map-First deve
/// agendar a próxima ação no pós-frame.
void main() {
  late String entrySheetSource;
  late String talhaoModalSource;

  setUpAll(() {
    entrySheetSource = File(
      'lib/modules/consultoria/clients/presentation/widgets/farm_map_entry_sheet.dart',
    ).readAsStringSync();
    talhaoModalSource = File(
      'lib/modules/consultoria/clients/presentation/widgets/client_detail_sub_widgets.dart',
    ).readAsStringSync();
  });

  test(
    'Continuar para desenhar agenda context.go após pop (pós-frame)',
    () {
      final popIdx = entrySheetSource.indexOf(
        'Navigator.of(context, rootNavigator: false).pop()',
      );
      final postFrameIdx = entrySheetSource.indexOf(
        'WidgetsBinding.instance.addPostFrameCallback',
        popIdx,
      );
      final goIdx = entrySheetSource.indexOf('context.go(target)', postFrameIdx);

      expect(popIdx, greaterThanOrEqualTo(0));
      expect(postFrameIdx, greaterThan(popIdx));
      expect(goIdx, greaterThan(postFrameIdx));
      expect(entrySheetSource, contains('modo=desenho'));
    },
  );

  test(
    'Desenhar no Mapa agenda showFarmMapEntrySheet após pop (pós-frame)',
    () {
      final drawStart = talhaoModalSource.indexOf("title: 'Desenhar no Mapa'");
      final drawEnd = talhaoModalSource.indexOf(
        "title: 'Importar KML ou KMZ'",
      );
      final drawOption = talhaoModalSource.substring(drawStart, drawEnd);

      final popIdx = drawOption.indexOf('.pop()');
      final postFrameIdx = drawOption.indexOf('addPostFrameCallback');
      final showIdx = drawOption.indexOf('showFarmMapEntrySheet');

      expect(popIdx, greaterThanOrEqualTo(0));
      expect(postFrameIdx, greaterThan(popIdx));
      expect(showIdx, greaterThan(postFrameIdx));
      expect(drawOption, contains('FarmMapEntryMode.draw'));
    },
  );
}
