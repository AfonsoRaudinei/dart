import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_presenter_provider.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/utils/area_display_format.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/agronomic_models.dart';
import '../../domain/client.dart';
import '../farm_map_download.dart';
import '../providers/clients_providers.dart';
import '../providers/field_providers.dart';
import '../providers/talhao_card_ndvi_provider.dart';
import '../widgets/client_detail_sub_widgets.dart';
import '../widgets/farm_linked_field_list.dart';
import '../widgets/link_drawing_to_farm_sheet.dart';
import '../widgets/talhao_actions_sheet.dart';
import '../widgets/talhao_map_preview.dart';

class ClientFarmWithTalhoesSection extends ConsumerStatefulWidget {
  final Client client;
  final Farm farm;
  final bool initiallyExpanded;

  const ClientFarmWithTalhoesSection({
    super.key,
    required this.client,
    required this.farm,
    this.initiallyExpanded = true,
  });

  @override
  ConsumerState<ClientFarmWithTalhoesSection> createState() =>
      _ClientFarmWithTalhoesSectionState();
}

class _ClientFarmWithTalhoesSectionState
    extends ConsumerState<ClientFarmWithTalhoesSection> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final farm = widget.farm;
    final fieldsAsync = ref.watch(farmLinkedFieldsProvider(farm.id));
    final linkedFields = fieldsAsync.asData?.value;
    final displayedAreaHa = linkedFields == null
        ? farm.totalAreaHa
        : totalFarmLinkedAreaHa(linkedFields);
    final areaUnit = ref.watch(areaDisplayUnitProvider);
    final areaFormatted = formatAreaFromHectares(displayedAreaHa, areaUnit);
    final toggleTooltip = _expanded ? 'Ocultar talhões' : 'Mostrar talhões';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        farm.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: toggleTooltip,
                      child: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Produtor: ${client.name}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Área Total', style: TextStyle(color: Colors.grey[600])),
              Text(
                areaFormatted,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${farm.city} - ${farm.state}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Talhões',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.go(
                  farmMapCreateUri(clientId: client.id, farmId: farm.id),
                ),
                icon: Icon(Icons.add, color: context.themeAccent),
                label: Text('Novo', style: TextStyle(
                    color: context.themeAccent,
                    fontWeight: FontWeight.bold,
                  )),
              ),
            ],
          ),
          FarmMapDownloadButton(farmId: farm.id, fields: linkedFields),
          const SizedBox(height: 8),
          fieldsAsync.when(
            data: (fields) => FarmLinkedFieldList(
              clientId: client.id,
              farmId: farm.id,
              fields: fields,
            ),
            loading: () {
              if ((linkedFields ?? const []).isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return FarmLinkedFieldList(
                clientId: client.id,
                farmId: farm.id,
                fields: linkedFields!,
              );
            },
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
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
                  icon: Icon(Icons.add, color: context.themeAccent),
                  label: Text('Talhão', style: TextStyle(
                      color: context.themeAccent,
                      fontWeight: FontWeight.bold,
                    )),
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
                final showNdvi = ref.watch(
                  talhaoCardNdviEnabledProvider(field.id),
                );
                final actions = <Widget>[
                  TalhaoCardNdviModeIconButton(
                    fieldId: field.id,
                    fieldName: field.name,
                    areaHa: field.areaHa,
                    onAfterSheetClosed: () =>
                        ref.invalidate(talhaoCardNdviLatestProvider(field.id)),
                  ),
                  IconButton(
                    tooltip: 'Vincular à fazenda',
                    icon: Icon(
                      Icons.link,
                      size: 20,
                      color: context.themeAccent,
                    ),
                    onPressed: () => _linkDrawingToFarm(context, ref, field),
                  ),
                  IconButton(
                    tooltip: 'Abrir no mapa',
                    icon: const Icon(Icons.open_in_full, size: 20),
                    onPressed: () => context.go(
                      _mapViewUri(
                        field,
                        ndvi: ref.read(talhaoCardNdviEnabledProvider(field.id)),
                      ),
                    ),
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
                ];

                void onOpenField() => showTalhaoDadosSheet(
                      context,
                      clientId: client.id,
                      farmId: field.farmId,
                      fieldId: field.id,
                      initialName: field.name,
                      initialCultura: field.crop,
                      initialMaterial: field.material,
                      initialSafra: field.harvest,
                    );

                if (showNdvi) {
                  return _DrawingTalhaoNdviCard(
                    field: field,
                    onOpenField: onOpenField,
                    actions: actions,
                    onNdviImageTap: () async {
                      await ref.read(ndviFieldPresenterProvider).showTalhaoSheet(
                            context,
                            fieldId: field.id,
                            fieldName: field.name,
                            areaHa: field.areaHa,
                          );
                      ref.invalidate(talhaoCardNdviLatestProvider(field.id));
                    },
                  );
                }

                return TalhaoMapPreviewWidget(
                  vertices: field.vertices,
                  boundsVertices: field.boundsVertices,
                  nome: field.name,
                  areaHa: field.areaHa,
                  subtitle: 'Sem fazenda vinculada',
                  onTap: onOpenField,
                  actions: actions,
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
    ref.invalidate(clientDrawingCropRowsProvider(client.id));
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
    ref.invalidate(clientDrawingCropRowsProvider(client.id));
    if (field.farmId != null) {
      ref.invalidate(farmLinkedFieldsProvider(field.farmId!));
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Talhão excluído.')));
  }

  String _mapViewUri(ClientDrawingFieldSummary field, {bool ndvi = false}) {
    return talhaoMapUri(
      modo: 'desenho',
      clientId: client.id,
      farmId: field.farmId,
      drawingId: field.id,
      ndvi: ndvi,
    );
  }
}

class _DrawingTalhaoNdviCard extends ConsumerWidget {
  const _DrawingTalhaoNdviCard({
    required this.field,
    required this.onOpenField,
    required this.actions,
    required this.onNdviImageTap,
  });

  final ClientDrawingFieldSummary field;
  final VoidCallback onOpenField;
  final List<Widget> actions;
  final VoidCallback onNdviImageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(talhaoCardNdviLatestProvider(field.id));
    return latestAsync.when(
      loading: () => _preview(
        ndviLoading: true,
        onNdviImageTap: onNdviImageTap,
      ),
      error: (_, _) => _preview(
        onNdviImageTap: onNdviImageTap,
      ),
      data: (summary) => _preview(
        ndviIsColormap: summary?.isColormap ?? false,
        ndviLocalPath: summary?.localPath,
        ndviImageUrl: summary?.imageUrl,
        ndviCaption: summary == null ? null : talhaoCardNdviCaption(summary),
        ndviBadge: summary == null ? null : talhaoCardNdviBadge(summary),
        onNdviImageTap: onNdviImageTap,
      ),
    );
  }

  Widget _preview({
    bool ndviLoading = false,
    bool ndviIsColormap = false,
    String? ndviLocalPath,
    String? ndviImageUrl,
    String? ndviCaption,
    String? ndviBadge,
    VoidCallback? onNdviImageTap,
  }) {
    return TalhaoMapPreviewWidget(
      vertices: field.vertices,
      boundsVertices: field.boundsVertices,
      nome: field.name,
      areaHa: field.areaHa,
      subtitle: 'Sem fazenda vinculada',
      onTap: onOpenField,
      actions: actions,
      showNdvi: true,
      ndviLoading: ndviLoading,
      ndviIsColormap: ndviIsColormap,
      ndviLocalPath: ndviLocalPath,
      ndviImageUrl: ndviImageUrl,
      ndviCaption: ndviCaption,
      ndviBadge: ndviBadge,
      onNdviImageTap: onNdviImageTap,
    );
  }
}
