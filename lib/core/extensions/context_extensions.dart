import 'package:flutter/material.dart';
import '../constants/layout_constants.dart';

/// Extensões de [BuildContext] para cálculos de layout dependentes
/// do SmartButton (FAB global).
extension FabSafeAreaExtension on BuildContext {
  /// Padding bottom total que respeita o SmartButton + safe area do dispositivo.
  ///
  /// Uso:
  /// ```dart
  /// padding: EdgeInsets.only(bottom: context.fabSafeBottomPadding),
  /// ```
  double get fabSafeBottomPadding =>
      kFabSafeArea + MediaQuery.of(this).padding.bottom;
}
