import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_keyboard_inset.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async => null;

  @override
  Future<List<ClientSummary>> listAtivos() async => const [];
}

class _EmptyVisitLookup implements IActiveVisitContextLookup {
  @override
  Future<ActiveVisitContext?> getActiveContext() async => null;
}

Widget _buildSheet({bool liftStickyActionsForKeyboard = true}) {
  return ProviderScope(
    overrides: [
      currentUserRoleProvider.overrideWithValue(UserRole.consultor),
      clientLookupProvider.overrideWithValue(_FakeClientLookup()),
      activeVisitContextLookupProvider.overrideWithValue(_EmptyVisitLookup()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(bottom: 34),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: OccurrenceCreationSheet(
          latitude: -10.12345,
          longitude: -48.54321,
          liftStickyActionsForKeyboard: liftStickyActionsForKeyboard,
          onConfirm: (_) async {},
        ),
      ),
    ),
  );
}

Padding _actionBarPadding(WidgetTester tester) {
  final paddings = tester.widgetList<Padding>(find.byType(Padding));
  return paddings.firstWhere((padding) {
    final resolved = padding.padding.resolve(TextDirection.ltr);
    return resolved.left == 16 &&
        resolved.right == 16 &&
        resolved.top == 12 &&
        resolved.bottom > 20;
  });
}

Future<void> setKeyboardViewForTest(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = const FakeViewPadding(bottom: 34);
  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewInsets);
}

void main() {
  testWidgets('teclado no modal levanta a barra Salvar', (tester) async {
    await setKeyboardViewForTest(tester);
    await tester.pumpWidget(_buildSheet());
    await tester.pump();

    final list = tester.widget<ListView>(find.byType(ListView).first);
    expect(
      list.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );

    final barPadding = _actionBarPadding(
      tester,
    ).padding.resolve(TextDirection.ltr);
    expect(
      barPadding.bottom,
      sheetStickyActionBottomPadding(
        safeBottom: 34,
        keyboard: 300,
        liftForKeyboard: true,
        closedExtra: kFabSafeArea,
      ),
    );

    final saveRect = tester.getRect(find.text('Salvar'));
    expect(saveRect.bottom, lessThan(844 - 300));
  });

  testWidgets('host do mapa não soma teclado no footer', (tester) async {
    await setKeyboardViewForTest(tester);
    await tester.pumpWidget(_buildSheet(liftStickyActionsForKeyboard: false));
    await tester.pump();

    final barPadding = _actionBarPadding(
      tester,
    ).padding.resolve(TextDirection.ltr);
    expect(
      barPadding.bottom,
      sheetStickyActionBottomPadding(
        safeBottom: 34,
        keyboard: 300,
        liftForKeyboard: false,
        closedExtra: kFabSafeArea,
      ),
    );
  });
}
