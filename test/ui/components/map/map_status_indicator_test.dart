import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_controls_overlay.dart';

void main() {
  group('resolveMapStatusIndicatorColor', () {
    test('vermelho quando offline (mesmo com radar preferido)', () {
      expect(
        resolveMapStatusIndicatorColor(isOnline: false, radarEnabled: true),
        const Color(0xFFFF3B30),
      );
      expect(
        resolveMapStatusIndicatorColor(isOnline: false, radarEnabled: false),
        const Color(0xFFFF3B30),
      );
    });

    test('verde quando online e radar desligado', () {
      expect(
        resolveMapStatusIndicatorColor(isOnline: true, radarEnabled: false),
        const Color(0xFF34C759),
      );
    });

    test('azul Samsung quando online e radar de chuva ativo', () {
      expect(
        resolveMapStatusIndicatorColor(isOnline: true, radarEnabled: true),
        const Color(0xFF1428A0),
      );
    });
  });
}
