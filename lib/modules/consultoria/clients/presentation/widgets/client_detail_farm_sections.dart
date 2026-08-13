import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/agronomic_models.dart';
import '../../domain/client.dart';
import '../providers/clients_providers.dart';
import '../providers/field_providers.dart';
import '../widgets/client_detail_sub_widgets.dart';
import '../widgets/link_drawing_to_farm_sheet.dart';
import '../widgets/talhao_map_preview.dart';

class ClientFarmWithTalhoesSection extends ConsumerWidget {
  final Client client;
  final Farm farm;

  const ClientFarmWithTalhoesSection({
    super.key,
    required this.client,
    required this.farm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(farmLinkedFieldsProvider(farm.id));
    final linkedFields = fieldsAsync.asData?.value;
    final displayedAreaHa = linkedFields == null
        ? farm.totalAreaHa
        : totalFarmLinkedAreaHa(linkedFields);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientFarmItem(
          name: farm.name,
          area: '${_formatAreaHa(displayedAreaHa)} ha',
          onTap: () => context.go(AppRoutes.farmDetail(client.id, farm.id)),
        ),
        fieldsAsync.when(
          data: (fields) {
            if (fields.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Column(
                children: fields.map((field) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
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
                            color: Colors.grey.shade100,
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
                        if (field.syncStatus != 0)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Tooltip(
                              message: 'Sincronização Pendente',
                              child: Icon(
                                Icons.cloud_off,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Talhões avulsos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.add,
                    color: PremiumTokens.brandGreen,
                  ),
                  label: const Text(
                    'Talhão',
                    style: TextStyle(
                      color: PremiumTokens.brandGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => showAdicionarTalhaoModal(context, client),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fields.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Nenhum talhão avulso no mapa',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...fields.map((field) {
                return TalhaoMapPreviewWidget(
                  vertices: field.vertices,
                  nome: field.name,
                  areaHa: field.areaHa,
                  subtitle: 'Sem fazenda vinculada',
                  onTap: () => context.go(_mapViewUri(field)),
                  actions: [
                    IconButton(
                      tooltip: 'Vincular à fazenda',
                      icon: const Icon(
                        Icons.link,
                        size: 20,
                        color: PremiumTokens.brandGreen,
                      ),
                      onPressed: () =>
                          _linkDrawingToFarm(context, ref, field),
                    ),
                    IconButton(
                      tooltip: 'Abrir no mapa',
                      icon: const Icon(Icons.open_in_full, size: 20),
                      onPressed: () => context.go(_mapViewUri(field)),
                    ),
                    IconButton(
                      tooltip: 'Editar no mapa',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => context.go(_mapEditUri(field)),
                    ),
                    IconButton(
                      tooltip: 'Excluir talhão',
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          _confirmDeleteDrawing(context, ref, field),
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

  Future<void> _linkDrawingToFarm(
    BuildContext context,
    WidgetRef ref,
    ClientDrawingFieldSummary field,
  ) async {
    final previousFarmId = field.farmId;
    final linkedFarm = await showLinkDrawingToFarmSheet(
      context,
      client: client,
      field: field,
    );
    if (linkedFarm == null || !context.mounted) return;

    ref.invalidate(clientDetailProvider(client.id));
    ref.invalidate(clientDrawingFieldsProvider(client.id));
    ref.invalidate(farmLinkedFieldsProvider(linkedFarm.id));
    if (previousFarmId != null && previousFarmId != linkedFarm.id) {
      ref.invalidate(farmLinkedFieldsProvider(previousFarmId));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Talhão vinculado à fazenda "${linkedFarm.name}".'),
      ),
    );
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
