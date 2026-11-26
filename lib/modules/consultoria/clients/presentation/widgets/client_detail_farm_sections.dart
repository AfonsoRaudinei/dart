import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_presenter_provider.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/utils/area_display_format.dart';
import 'package:soloforte_app/modules/consultoria/farms/data/repositories/farm_repository.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/agronomic_models.dart';
import '../../domain/client.dart';
import '../farm_geometry_export.dart';
import '../farm_map_download.dart';
import '../farm_delete_guard.dart';
import '../providers/clients_providers.dart';
import '../providers/field_providers.dart';
import '../providers/talhao_card_ndvi_provider.dart';
import '../widgets/client_detail_sub_widgets.dart';
import '../widgets/create_farm_sheet.dart';
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

  Future<void> _editFarm(BuildContext context) async {
    final client = widget.client;
    final farm = widget.farm;
    final fields = await ref.read(farmLinkedFieldsProvider(farm.id).future);
    if (!context.mounted) return;

    await showEditFarmSheet(
      context,
      client: client,
      farm: farm,
      areaFromLinkedFields: fields.isNotEmpty,
      onFarmUpdated: (_) {
        ref.invalidate(clientDetailProvider(client.id));
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fazenda atualizada.')));
      },
    );
  }

  Future<void> _deleteFarm(BuildContext context) async {
    final client = widget.client;
    final farm = widget.farm;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir fazenda?'),
        content: Text(
          'A fazenda "${farm.name}" será removida da lista deste cliente.',
        ),
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

    final fields = await ref.read(farmLinkedFieldsProvider(farm.id).future);
    try {
      ensureFarmDeletable(linkedFieldCount: fields.length);
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    await FarmRepository().deleteFarm(farm.id);
    ref.invalidate(clientDetailProvider(client.id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fazenda excluída.')));
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
    final location = farmLocationLabel(farm);
    final accent = context.themeAccent;
    final divider = Divider(
      height: 1,
      thickness: 0.5,
      color: context.premiumHairline,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.premiumSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.premiumCardBorder),
          boxShadow: context.premiumCardShadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: _toggleExpanded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.agriculture_rounded,
                                color: accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      farm.name,
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                        color: context.premiumTextPrimary,
                                      ),
                                    ),
                                    if (location != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.place_outlined,
                                            size: 14,
                                            color: context.premiumTextSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              location,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: context
                                                    .premiumTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Opções da fazenda',
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                color: context.premiumTextSecondary,
                              ),
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _editFarm(context);
                                  case 'delete':
                                    _deleteFarm(context);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Editar fazenda'),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      'Excluir fazenda',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ),
                              ],
                            ),
                            Tooltip(
                              message: toggleTooltip,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  4,
                                  12,
                                  8,
                                  12,
                                ),
                                child: AnimatedRotation(
                                  turns: _expanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    color: context.premiumTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: divider,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Área Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: context.premiumTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      areaFormatted,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: context.premiumTextPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _FarmFieldCountPill(count: linkedFields?.length),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_expanded) ...[
                  divider,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Talhões',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.premiumTextPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => showAdicionarTalhaoModal(
                                context,
                                client,
                                farm: farm,
                              ),
                              icon: Icon(Icons.add, color: accent),
                              label: Text(
                                'Novo',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // A linha "Baixar mapa" + exportar não quebra e
                        // estoura em telas estreitas / texto ampliado.
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: FarmMapDownloadButton(
                            farmId: farm.id,
                            fields: linkedFields,
                            trailing: FarmGeometryExportButton(
                              documentName: farm.name,
                              fields: linkedFields,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        fieldsAsync.when(
                          data: (fields) => FarmLinkedFieldList(
                            clientId: client.id,
                            farmId: farm.id,
                            fields: fields,
                          ),
                          loading: () {
                            if ((linkedFields ?? const []).isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
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
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "{cidade} - {UF}" sem partes vazias; `null` quando não há localização.
String? farmLocationLabel(Farm farm) {
  final parts = [
    farm.city.trim(),
    farm.state.trim(),
  ].where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? null : parts.join(' - ');
}

/// "Sem talhões" · "1 talhão" · "N talhões"; `null` (carregando) vira "—".
String farmFieldCountLabel(int? count) {
  if (count == null) return '—';
  if (count == 0) return 'Sem talhões';
  if (count == 1) return '1 talhão';
  return '$count talhões';
}

class _FarmFieldCountPill extends StatelessWidget {
  const _FarmFieldCountPill({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final hasFields = (count ?? 0) > 0;
    final color = hasFields
        ? context.themeAccent
        : context.premiumTextSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_view_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            farmFieldCountLabel(count),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
                  label: Text(
                    'Talhão',
                    style: TextStyle(
                      color: context.themeAccent,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.premiumSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.premiumCardBorder),
                  boxShadow: context.premiumCardShadows,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.crop_free_rounded,
                      size: 28,
                      color: context.premiumTextTertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhum talhão avulso no mapa',
                      style: TextStyle(color: context.premiumTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...fields.map((field) {
                final showNdvi = ref.watch(
                  talhaoCardNdviEnabledProvider(field.id),
                );
                final actions = <Widget>[
                  _labeledAction(
                    'NDVI',
                    TalhaoCardNdviModeIconButton(
                      fieldId: field.id,
                      fieldName: field.name,
                      areaHa: field.areaHa,
                      onAfterSheetClosed: () => ref.invalidate(
                        talhaoCardNdviLatestProvider(field.id),
                      ),
                    ),
                  ),
                  _labeledAction(
                    'Vincular',
                    IconButton(
                      tooltip: 'Vincular à fazenda',
                      icon: Icon(
                        Icons.link,
                        size: 20,
                        color: context.themeAccent,
                      ),
                      onPressed: () => _linkDrawingToFarm(context, ref, field),
                    ),
                  ),
                  _labeledAction(
                    'Mapa',
                    IconButton(
                      tooltip: 'Abrir no mapa',
                      icon: const Icon(Icons.open_in_full, size: 20),
                      onPressed: () => context.go(
                        _mapViewUri(
                          field,
                          ndvi: ref.read(
                            talhaoCardNdviEnabledProvider(field.id),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (canOfferFieldGeometryExport(
                    geojson: field.geojson,
                    vertexCount: field.vertices.length,
                  ))
                    _labeledAction(
                      'KML',
                      IconButton(
                        tooltip: 'Exportar KML',
                        icon: const Icon(Icons.ios_share_outlined, size: 20),
                        onPressed: () => exportFieldGeometries(
                          context: context,
                          documentName: field.name,
                          items: [
                            FarmGeometryExportItem(
                              name: field.name,
                              areaHa: field.areaHa,
                              geojson: field.geojson,
                            ),
                          ],
                        ),
                      ),
                    ),
                  _labeledAction(
                    'Excluir',
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
                  initialDataPlantio: field.dataPlantio,
                  initialDataEmergencia: field.dataEmergencia,
                  initialCicloDias: field.cicloDias,
                );

                if (showNdvi) {
                  return _DrawingTalhaoNdviCard(
                    field: field,
                    onOpenField: onOpenField,
                    actions: actions,
                    onNdviImageTap: () async {
                      await ref
                          .read(ndviFieldPresenterProvider)
                          .showTalhaoSheet(
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
    ref.invalidate(clientListCulturaIndexProvider);
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
    ref.invalidate(clientListCulturaIndexProvider);
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
      loading: () =>
          _preview(ndviLoading: true, onNdviImageTap: onNdviImageTap),
      error: (_, _) => _preview(onNdviImageTap: onNdviImageTap),
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

/// Ação do cartão com texto visível abaixo do ícone (antes só havia tooltip).
Widget _labeledAction(String label, Widget action) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      action,
      Text(
        label,
        style: const TextStyle(fontSize: 10.5, color: Colors.black54),
      ),
    ],
  );
}
