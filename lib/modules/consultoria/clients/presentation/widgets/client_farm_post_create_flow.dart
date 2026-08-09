import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/agronomic_models.dart';
import '../../domain/client.dart';
import '../providers/clients_providers.dart';
import '../providers/field_providers.dart';
import 'link_drawing_to_farm_sheet.dart';

/// Pós-criação de fazenda: oferece vincular talhões avulsos (opcional).
Future<void> offerLinkOrphanDrawingsAfterFarmCreated({
  required BuildContext context,
  required WidgetRef ref,
  required Client client,
  required Farm farm,
}) async {
  ref.invalidate(clientDetailProvider(client.id));
  ref.invalidate(clientDrawingFieldsProvider(client.id));
  ref.invalidate(farmLinkedFieldsProvider(farm.id));

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Fazenda cadastrada.')),
  );

  final orphans = await ref.read(clientDrawingFieldsProvider(client.id).future);
  if (!context.mounted || orphans.isEmpty) return;

  final linkNow = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Vincular talhões avulsos?'),
      content: Text(
        orphans.length == 1
            ? 'Deseja vincular "${orphans.first.name}" à fazenda "${farm.name}"?'
            : 'Existem ${orphans.length} talhões avulsos. Deseja vincular à fazenda "${farm.name}"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Depois'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Vincular agora'),
        ),
      ],
    ),
  );

  if (linkNow != true || !context.mounted) return;

  for (final orphan in orphans) {
    if (!context.mounted) return;
    final linkedFarm = await showLinkDrawingToFarmSheet(
      context,
      client: client,
      field: orphan,
      preselectedFarmId: farm.id,
    );
    if (!context.mounted) return;
    if (linkedFarm == null) break;

    ref.invalidate(clientDetailProvider(client.id));
    ref.invalidate(clientDrawingFieldsProvider(client.id));
    ref.invalidate(farmLinkedFieldsProvider(linkedFarm.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Talhão "${orphan.name}" vinculado à fazenda "${linkedFarm.name}".',
        ),
      ),
    );
  }
}
