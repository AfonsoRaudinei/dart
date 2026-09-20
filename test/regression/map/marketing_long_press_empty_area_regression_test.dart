import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Blindagem: long press de marketing/ocorrência em cima do talhão.
///
/// O viewport pós-login (GPS zoom 16 ou fit dos talhões) cobre a fazenda.
/// Bloquear o gesto por `fieldHitIndex` impedia criar pin exatamente onde
/// o consultor está. Desenho e pin existente continuam bloqueando.
///
/// O segundo sheet (Resultado/Antes-Depois/Avaliação) não pode abrir na
/// mesma frame do `Navigator.pop` do menu de ações — corrida com
/// `showSoloForteSheet`.
void main() {
  late String hitTestSource;
  late String privateMapSource;
  late String actionsSheetSource;

  setUpAll(() {
    hitTestSource = File(
      'lib/ui/screens/map/utils/map_empty_area_hit_test.dart',
    ).readAsStringSync();
    privateMapSource = File(
      'lib/ui/screens/private_map_screen.dart',
    ).readAsStringSync();
    actionsSheetSource = File(
      'lib/ui/components/map/widgets/publication_actions_bottom_sheet.dart',
    ).readAsStringSync();
  });

  test('isEmptyMapArea não bloqueia por talhão', () {
    expect(hitTestSource, isNot(contains('fieldHitIndex.hitTest')));
    expect(hitTestSource, isNot(contains('TalhaoMapAdapter')));
  });

  test('isEmptyMapArea ainda bloqueia desenho e pin', () {
    expect(hitTestSource, contains('findFeatureAt'));
    expect(hitTestSource, contains('kMapPinHitTestRadiusPx'));
  });

  test('_handleMapLongPress abre ações rápidas e launcher de case', () {
    final handlerStart = privateMapSource.indexOf('void _handleMapLongPress');
    expect(handlerStart, greaterThanOrEqualTo(0));
    final handlerEnd = privateMapSource.indexOf(
      'bool _isEmptyMapArea',
      handlerStart,
    );
    final handler = privateMapSource.substring(handlerStart, handlerEnd);

    expect(handler, contains('PublicationActionsBottomSheet'));
    expect(handler, contains('NovoCaseModalLauncher'));
  });

  test('_select faz pop antes do pós-frame e action() dentro do callback', () {
    final selectStart = actionsSheetSource.indexOf(
      'void _select(BuildContext context, VoidCallback action)',
    );
    expect(selectStart, greaterThanOrEqualTo(0));
    final selectEnd = actionsSheetSource.indexOf('@override', selectStart);
    final select = actionsSheetSource.substring(selectStart, selectEnd);

    final popIdx = select.indexOf('Navigator.of(context).pop()');
    final postFrameIdx = select.indexOf('addPostFrameCallback');
    final actionIdx = select.indexOf('action();');

    expect(popIdx, greaterThanOrEqualTo(0));
    expect(postFrameIdx, greaterThan(popIdx));
    expect(actionIdx, greaterThan(postFrameIdx));
  });
}
