import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/login/login_sheet_drag.dart';

void main() {
  group('LoginSheetDrag.shouldDismiss', () {
    test('soltar perto da origem não fecha', () {
      expect(LoginSheetDrag.shouldDismiss(offset: 0, velocity: 0), isFalse);
      expect(LoginSheetDrag.shouldDismiss(offset: 119, velocity: 0), isFalse);
    });

    test('soltar além da distância fecha', () {
      expect(
        LoginSheetDrag.shouldDismiss(
          offset: LoginSheetDrag.dismissDistance,
          velocity: 0,
        ),
        isTrue,
      );
    });

    test('velocidade para baixo fecha mesmo com pouco deslocamento', () {
      expect(
        LoginSheetDrag.shouldDismiss(
          offset: 10,
          velocity: LoginSheetDrag.dismissVelocity,
        ),
        isTrue,
      );
      expect(LoginSheetDrag.shouldDismiss(offset: 10, velocity: 699), isFalse);
    });

    test('gesto rápido para cima cancela o fechamento', () {
      expect(
        LoginSheetDrag.shouldDismiss(
          offset: 400,
          velocity: -LoginSheetDrag.dismissVelocity,
        ),
        isFalse,
      );
    });
  });

  test('clampOffset não deixa o painel subir nem passar do teto', () {
    expect(LoginSheetDrag.clampOffset(-20), 0);
    expect(LoginSheetDrag.clampOffset(40), 40);
    expect(LoginSheetDrag.clampOffset(900), LoginSheetDrag.maxOffset);
  });
}
