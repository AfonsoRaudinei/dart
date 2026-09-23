import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_presenter_provider.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/domain/cultura_tipo.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/utils/area_display_format.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_actions_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_union_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_map_preview.dart';

String formatLinkedFieldAreaHa(double areaHa) {
  return areaHa.toStringAsFixed(areaHa >= 100 ? 1 : 2);
}

String farmLinkedFieldSubtitle(
  FarmLinkedFieldSummary field,
  AreaDisplayUnit unit,
) {
  final parts = <String>[formatAreaFromHectares(field.areaHa, unit)];

  if (field.crop != null && field.crop!.trim().isNotEmpty) {
    parts.add(CulturaTipo.displayLabel(field.crop));
  }

  if (field.material != null && field.material!.trim().isNotEmpty) {
    parts.add(field.material!.trim());
  }

  return parts.join(' • ');
}

/// Lookup da última imagem só é observado pelo card quando o segmento NDVI
/// está ligado. No modo Mapa o provider não é lido.
final talhaoCardNdviLatestProvider = FutureProvider.autoDispose
    .family<NdviLatestSummary?, String>((ref, fieldId) {
      return ref.watch(ndviLatestLookupProvider).getLatest(fieldId);
    });

/// `0.62 · 12/09` — média com 2 casas e dia/mês com 2 dígitos.
/// Preview RGB não tem média NDVI; o default 0 não entra na legenda.
String? talhaoCardNdviCaption(NdviLatestSummary summary) {
  if (!summary.isColormap || !_summaryHasRenderableImage(summary)) return null;
  final mean = summary.ndviMean.toStringAsFixed(2);
  final day = summary.imageDate.day.toString().padLeft(2, '0');
  final month = summary.imageDate.month.toString().padLeft(2, '0');
  return '$mean · $day/$month';
}

/// Selo do card quando a imagem existe e não é raster NDVI.
String? talhaoCardNdviBadge(NdviLatestSummary summary) {
  if (summary.isColormap || !_summaryHasRenderableImage(summary)) return null;
  return 'Preview RGB';
}

bool _summaryHasRenderableImage(NdviLatestSummary summary) {
  final hasLocal = summary.localPath != null && summary.localPath!.isNotEmpty;
  final hasUrl =
      summary.imageUrl != null && summary.imageUrl!.trim().isNotEmpty;
  return hasLocal || hasUrl;
}

class FarmLinkedFieldList extends ConsumerWidget {
  final String clientId;
  final String farmId;
  final List<FarmLinkedFieldSummary> fields;
  final String emptyMessage;
  final bool showNdvi;

  const FarmLinkedFieldList({
    super.key,
    required this.clientId,
    required this.farmId,
    required this.fields,
    this.emptyMessage = 'Nenhum talhão cadastrado',
    this.showNdvi = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areaUnit = ref.watch(areaDisplayUnitProvider);

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
      children: [
        for (final field in fields)
          if (showNdvi)
            _FarmTalhaoNdviCard(
              field: field,
              areaUnit: areaUnit,
              onOpenField: () => _openField(context, field),
              actions: _fieldActions(context, ref, field),
              onNdviImageTap: () {
                ref
                    .read(ndviFieldPresenterProvider)
                    .showTalhaoSheet(
                      context,
                      fieldId: field.id,
                      fieldName: field.name,
                      areaHa: field.areaHa,
                    );
              },
            )
          else
            TalhaoMapPreviewWidget(
              vertices: field.vertices,
              nome: field.name,
              areaHa: field.areaHa,
              subtitle: farmLinkedFieldSubtitle(field, areaUnit),
              onTap: () => _openField(context, field),
              actions: _fieldActions(context, ref, field),
            ),
      ],
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
          tooltip: 'Dados do talhão',
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _openField(context, field),
        ),
        IconButton(
          tooltip: 'Geometria e união',
          icon: const Icon(Icons.more_horiz, size: 20),
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
      showTalhaoDadosSheet(
        context,
        clientId: clientId,
        farmId: farmId,
        fieldId: field.id,
        initialName: field.name,
        initialCultura: field.crop,
        initialMaterial: field.material,
        initialSafra: field.harvest,
      );
      return;
    }

    context.go(AppRoutes.fieldDetail(clientId, farmId, field.id));
  }

  List<TalhaoUnionCandidate> _unionCandidates(FarmLinkedFieldSummary field) {
    return fields
        .where((candidate) => candidate.isDrawing && candidate.id != field.id)
        .map(
          (candidate) => TalhaoUnionCandidate(
            id: candidate.id,
            name: candidate.name,
            areaHa: candidate.areaHa,
            vertices: candidate.vertices,
          ),
        )
        .toList();
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
      initialCultura: field.crop,
      initialMaterial: field.material,
      initialSafra: field.harvest,
      fieldAreaHa: field.areaHa,
      primaryVertices: field.vertices,
      showUnionAction: field.isDrawing,
      unionCandidates: _unionCandidates(field),
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
    ref.invalidate(clientDrawingCropRowsProvider(clientId));
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
      ndvi: showNdvi,
    );
  }
}

/// Existe só com o segmento NDVI ligado, para o lookup não rodar no modo Mapa.
class _FarmTalhaoNdviCard extends ConsumerWidget {
  const _FarmTalhaoNdviCard({
    required this.field,
    required this.areaUnit,
    required this.onOpenField,
    required this.actions,
    required this.onNdviImageTap,
  });

  final FarmLinkedFieldSummary field;
  final AreaDisplayUnit areaUnit;
  final VoidCallback onOpenField;
  final List<Widget> actions;
  final VoidCallback onNdviImageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(talhaoCardNdviLatestProvider(field.id));
    return latestAsync.when(
      loading: () => Stack(
        children: [
          _preview(),
          const Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
      error: (_, _) => _preview(showNdvi: true),
      data: (summary) => _preview(
        showNdvi: true,
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
    bool showNdvi = false,
    bool ndviIsColormap = false,
    String? ndviLocalPath,
    String? ndviImageUrl,
    String? ndviCaption,
    String? ndviBadge,
    VoidCallback? onNdviImageTap,
  }) {
    return TalhaoMapPreviewWidget(
      vertices: field.vertices,
      nome: field.name,
      areaHa: field.areaHa,
      subtitle: farmLinkedFieldSubtitle(field, areaUnit),
      onTap: onOpenField,
      actions: actions,
      showNdvi: showNdvi,
      ndviIsColormap: ndviIsColormap,
      ndviLocalPath: ndviLocalPath,
      ndviImageUrl: ndviImageUrl,
      ndviCaption: ndviCaption,
      ndviBadge: ndviBadge,
      onNdviImageTap: onNdviImageTap,
    );
  }
}

String farmMapCreateUri({required String clientId, required String farmId}) {
  return Uri(
    path: AppRoutes.map,
    queryParameters: {
      'modo': 'desenho',
      'clienteId': clientId,
      'fazendaId': farmId,
    },
  ).toString();
}
