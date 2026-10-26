import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_map_gesture_overlay.dart';

void main() {
  group('DrawingMapGestureOverlay.excludesMapChromePointer', () {
    const size = Size(390, 844);
    const safeBottom = 34.0;

    test('centro do mapa não é chrome', () {
      expect(
        DrawingMapGestureOverlay.excludesMapChromePointer(
          const Offset(195, 400),
          size,
          safeBottom: safeBottom,
          drawingState: DrawingState.armed,
        ),
        isFalse,
      );
    });

    test('faixa inferior da toolbar é chrome só em drawing', () {
      final y = size.height - safeBottom - 20;
      expect(
        DrawingMapGestureOverlay.excludesMapChromePointer(
          Offset(100, y),
          size,
          safeBottom: safeBottom,
          drawingState: DrawingState.drawing,
        ),
        isTrue,
      );
      expect(
        DrawingMapGestureOverlay.excludesMapChromePointer(
          Offset(100, y),
          size,
          safeBottom: safeBottom,
          drawingState: DrawingState.armed,
        ),
        isFalse,
      );
    });

    test('coluna direita alta não é chrome em armed', () {
      expect(
        DrawingMapGestureOverlay.excludesMapChromePointer(
          Offset(
            size.width - kMapActionColumnRightInset,
            200,
          ),
          size,
          safeBottom: safeBottom,
          drawingState: DrawingState.armed,
        ),
        isFalse,
      );
    });

    test('coluna direita perto da base é chrome', () {
      final y = size.height - safeBottom - kMapActionColumnBottomInset;
      expect(
        DrawingMapGestureOverlay.excludesMapChromePointer(
          Offset(
            size.width - kMapActionColumnRightInset,
            y,
          ),
          size,
          safeBottom: safeBottom,
          drawingState: DrawingState.armed,
        ),
        isTrue,
      );
    });
  });
}
