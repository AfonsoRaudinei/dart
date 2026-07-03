import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

import '../../domain/agronomic_models.dart';
import '../../domain/client.dart';
import '../providers/field_providers.dart';
import 'client_detail_sub_widgets.dart';
import 'talhao_map_preview.dart';

/// Fazenda do cliente com talhões vinculados (fields + drawings).
class ClientFarmWithTalhoes extends ConsumerWidget {
  final Client client;
  final Farm farm;

  const ClientFarmWithTalhoes({
    super.key,
    required this.client,
    required this.farm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(farmLinkedFieldsProvider(farm.id));
    final linkedFields = fieldsAsync.asData?.value;
    final isLoadingArea = fieldsAsync.isLoading;
    final displayedAreaHa = isLoadingArea
        ? null
        : linkedFields == null
        ? farm.totalAreaHa
        : totalFarmLinkedAreaHa(linkedFields);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientFarmItem(
          name: farm.name,
          area: isLoadingArea
              ? '— ha'
              : '${_formatAreaHa(displayedAreaHa ?? 0)} ha',
          onTap: () => context.go(AppRoutes.farmDetail(client.id, farm.id)),
        ),
        fieldsAsync.when(
          data: (fields) {
            if (fields.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Column(
                children: fields.map((field) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: field.isDrawing
                          ? () => context.go(_mapEditUriForFarmField(field))
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(8),
                                image: field.thumbnailPath != null
                                    ? DecorationImage(
                                        image: FileImage(
                                          File(field.thumbnailPath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: field.thumbnailPath == null
                                  ? Icon(
                                      field.isDrawing
                                          ? Icons.map_outlined
                                          : Icons.terrain,
                                      color: Colors.grey.shade400,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _farmFieldSubtitle(field),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (field.isDrawing)
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: 12.0, left: 16),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _mapEditUriForFarmField(FarmLinkedFieldSummary field) {
    return Uri(
      path: AppRoutes.map,
      queryParameters: {
        'modo': 'editar',
        'clienteId': client.id,
        'fazendaId': farm.id,
        'drawingId': field.id,
      },
    ).toString();
  }

  String _farmFieldSubtitle(FarmLinkedFieldSummary field) {
    final parts = <String>['Área: ${_formatAreaHa(field.areaHa)} ha'];
    if (field.perimeter != null) {
      parts.add('Perímetro: ${field.perimeter!.toStringAsFixed(2)} km');
    }
    if (field.isDrawing) {
      parts.add('Talhão do mapa');
    }
    return parts.join(' • ');
  }

  String _formatAreaHa(double areaHa) {
    return areaHa.toStringAsFixed(areaHa >= 100 ? 1 : 2);
  }
}

/// Seção "Talhões do mapa" na tela de detalhe do cliente.
class ClientDrawingFieldsSection extends ConsumerWidget {
  final Client client;

  const ClientDrawingFieldsSection({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingFieldsAsync = ref.watch(
      clientDrawingFieldsProvider(client.id),
    );

    return drawingFieldsAsync.when(
      data: (fields) {
        if (fields.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talhões do mapa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...fields.map((field) {
              final farmName = field.farmId == null
                  ? null
                  : _findFarmName(client, field.farmId!);

              return TalhaoMapPreviewWidget(
                vertices: field.vertices,
                polygons: field.polygons,
                nome: field.name,
                areaHa: field.areaHa,
                subtitle: farmName == null ? null : 'Fazenda: $farmName',
                onTap: () => context.go(_mapViewUri(field)),
                actions: [
                  IconButton(
                    tooltip: 'Abrir no mapa',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.open_in_full, size: 20),
                    onPressed: () => context.go(_mapViewUri(field)),
                  ),
                  IconButton(
                    tooltip: 'Editar no mapa',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => context.go(_mapEditUri(field)),
                  ),
                  IconButton(
                    tooltip: 'Excluir talhão',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: () => _confirmDeleteDrawing(context, ref, field),
                  ),
                ],
              );
            }),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String? _findFarmName(Client client, String farmId) {
    for (final farm in client.farms) {
      if (farm.id == farmId) return farm.name;
    }
    return null;
  }

  Future<void> _confirmDeleteDrawing(
    BuildContext context,
    WidgetRef ref,
    ClientDrawingFieldSummary field,
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
          clientId: client.id,
        );

    ref.invalidate(clientDrawingFieldsProvider(client.id));
    if (field.farmId != null) {
      ref.invalidate(farmLinkedFieldsProvider(field.farmId!));
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Talhão excluído.')));
  }

  String _mapViewUri(ClientDrawingFieldSummary field) {
    return Uri(
      path: AppRoutes.map,
      queryParameters: {
        'modo': 'desenho',
        'clienteId': client.id,
        if (field.farmId != null) 'fazendaId': field.farmId!,
        'drawingId': field.id,
      },
    ).toString();
  }

  String _mapEditUri(ClientDrawingFieldSummary field) {
    return Uri(
      path: AppRoutes.map,
      queryParameters: {
        'modo': 'editar',
        'clienteId': client.id,
        if (field.farmId != null) 'fazendaId': field.farmId!,
        'drawingId': field.id,
      },
    ).toString();
  }
}
