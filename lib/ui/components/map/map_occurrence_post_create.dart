import 'package:flutter/material.dart';

import '../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import '../../theme/premium/design_tokens.dart';
import 'widgets/location_export_bottom_sheet.dart';

/// Pós-criação de ocorrência no mapa: export (área visitada) + feedback.
Future<void> handleMapOccurrencePostCreate({
  required BuildContext context,
  required OccurrenceFormData data,
  required VoidCallback onClose,
}) async {
  final isAreaVisitada = isAreaVisitadaCategory(data.category);
  if (isAreaVisitada) {
    await LocationExportBottomSheet.show(
      context: context,
      latitude: data.latitude,
      longitude: data.longitude,
      label: 'Área Visitada',
    );
  }

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        isAreaVisitada
            ? 'Local marcado com sucesso'
            : 'Ocorrência registrada com sucesso!',
      ),
      backgroundColor: PremiumTokens.brandGreen,
    ),
  );

  onClose();
}
