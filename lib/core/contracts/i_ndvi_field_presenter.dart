import 'package:flutter/widgets.dart';

/// Abre UI de NDVI para um talhão sem acoplar consumidores ao módulo ndvi/.
/// ADR-045.
abstract interface class INdviFieldPresenter {
  Future<void> showTalhaoSheet(
    BuildContext context, {
    required String fieldId,
    required String fieldName,
    double? areaHa,
  });
}
