import 'package:flutter/material.dart';

import '../../../core/contracts/i_ndvi_field_presenter.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import '../presentation/widgets/ndvi_talhao_sheet.dart';

/// Implementação de INdviFieldPresenter — dona da UI NDVI. ADR-045.
class NdviFieldPresenterAdapter implements INdviFieldPresenter {
  const NdviFieldPresenterAdapter();

  @override
  Future<void> showTalhaoSheet(
    BuildContext context, {
    required String fieldId,
    required String fieldName,
    double? areaHa,
  }) {
    // Sem backgroundColor/shape hardcoded — chrome iOS Azul via showSoloForteSheet.
    return showSoloForteSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: false,
      builder: (_) => NdviTalhaoSheet(
        fieldId: fieldId,
        fieldName: fieldName,
        areaHa: areaHa,
      ),
    );
  }
}
