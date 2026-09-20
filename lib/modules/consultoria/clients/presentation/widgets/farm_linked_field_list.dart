import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_actions_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_map_preview.dart';

String formatLinkedFieldAreaHa(double areaHa) {
  return areaHa.toStringAsFixed(areaHa >= 100 ? 1 : 2);
}

String farmLinkedFieldSubtitle(FarmLinkedFieldSummary field) {
  final parts = <String>['${formatLinkedFieldAreaHa(field.areaHa)} ha'];

  if (field.isDrawing) {
    parts.add('Talhão do mapa');
  }

  if (field.crop != null && field.crop!.trim().isNotEmpty) {
    parts.add(field.crop!.trim());
  }

  return parts.join(' • ');
}

class FarmLinkedFieldList extends ConsumerWidget {
  final String clientId;
  final String farmId;
  final List<FarmLinkedFieldSummary> fields;
  final String emptyMessage;

  const FarmLinkedFieldList({
    super.key,
    required this.clientId,
    required this.farmId,
    required this.fields,
    this.emptyMessage = 'Nenhum talhão cadastrado',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(child: Text(emptyMessage)),
      );
    }

    return Column(
      children: fields.map((field) {
        return TalhaoMapPreviewWidget(
          vertices: field.vertices,
          nome: field.name,
          areaHa: field.areaHa,
          subtitle: farmLinkedFieldSubtitle(field),
          onTap: () => _openField(context, field),
          actions: _fieldActions(context, ref, field),
        );
      }).toList(),
    );
  }

  List<Widget> _fieldActions(
    BuildContext context,
    WidgetRef ref,
    FarmLinkedFieldSummary field,
  ) {
    final actions = <Widget>[
      IconButton(
        tooltip: 'Abrir no mapa',
        icon: const Icon(Icons.open_in_full, size: 20),
        onPressed: () => context.go(_mapViewUri(field.id)),
      ),
    ];

    if (field.isDrawing) {
      actions.addAll([
        IconButton(
          tooltip: 'Ações do talhão',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _openActions(context, field),
        ),
        IconButton(
          tooltip: 'Excluir talhão',
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          onPressed: () => _confirmDeleteDrawing(context, ref, field),
        ),
      ]);
    }

    return actions;
  }

  void _openField(BuildContext context, FarmLinkedFieldSummary field) {
    if (field.isDrawing) {
      _openActions(context, field);
      return;
    }

    context.go(AppRoutes.fieldDetail(clientId, farmId, field.id));
  }

  Future<void> _openActions(
    BuildContext context,
    FarmLinkedFieldSummary field,
  ) {
    return showTalhaoActionsSheet(
      context,
      clientId: clientId,
      farmId: farmId,
      fieldId: field.id,
      fieldName: field.name,
    );
  }

  Future<void> _confirmDeleteDrawing(
    BuildContext context,
    WidgetRef ref,
    FarmLinkedFieldSummary field,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir talhão?'),
        content: Text('O talhão "${field.name}" será removido do mapa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref
        .read(iDrawingFieldWriterProvider)
        .deleteFieldAndRecalculateClientArea(
          fieldId: field.id,
          clientId: clientId,
        );

    ref.invalidate(farmLinkedFieldsProvider(farmId));
    ref.invalidate(clientDrawingFieldsProvider(clientId));
    ref.invalidate(clientDetailProvider(clientId));

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Talhão excluído.')));
  }

  String _mapViewUri(String drawingId) {
    return talhaoMapUri(
      modo: 'desenho',
      clientId: clientId,
      farmId: farmId,
      drawingId: drawingId,
    );
  }
}

String farmMapCreateUri({
  required String clientId,
  required String farmId,
}) {
  return Uri(
    path: AppRoutes.map,
    queryParameters: {
      'modo': 'desenho',
      'clienteId': clientId,
      'fazendaId': farmId,
    },
  ).toString();
}
