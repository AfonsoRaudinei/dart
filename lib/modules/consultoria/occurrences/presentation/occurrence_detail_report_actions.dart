import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/contracts/i_farm_lookup_provider.dart';
import '../../../../core/contracts/i_field_lookup_provider.dart';
import '../../../../core/contracts/i_visit_session_lookup_provider.dart';
import '../../../../core/html_templates/html_report_viewer.dart';
import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../../../core/html_templates/report_export_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../core/utils/share_position.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../relatorios/infra/consultoria_report_export_data.dart';
import '../../relatorios/infra/occurrence_report_html_builder.dart';
import '../../relatorios/presentation/relatorios_occurrence_location_resolver.dart';
import 'controllers/occurrence_controller.dart';
import '../domain/occurrence.dart';
import 'widgets/occurrence_creation_sheet.dart';

HtmlReportViewerActions occurrenceReportHtmlViewerActions(
  ProviderContainer container,
  Occurrence occurrence, {
  bool closeParentSheetOnAction = false,
  BuildContext? parentSheetContext,
}) {
  final repository = container.read(occurrenceRepositoryProvider);
  final lat = occurrence.lat;
  final lng = occurrence.long;
  final hasLocation = lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      !(lat == 0 && lng == 0);

  void popParentSheet() {
    if (!closeParentSheetOnAction || parentSheetContext == null) return;
    if (parentSheetContext.mounted) {
      Navigator.of(parentSheetContext).pop();
    }
  }

  void schedulePopParentSheetAfterViewer() {
    if (!closeParentSheetOnAction || parentSheetContext == null) return;
    final capturedContext = parentSheetContext;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (capturedContext.mounted) {
        Navigator.of(capturedContext).pop();
      }
    });
  }

  return HtmlReportViewerActions(
    onEdit: (viewerContext) async {
      Navigator.of(viewerContext).pop();
      if (closeParentSheetOnAction && parentSheetContext != null) {
        final navigator = Navigator.of(parentSheetContext);
        final sheetHostContext = navigator.context;
        navigator.pop();
        if (!sheetHostContext.mounted) return;
        await _showOccurrenceEditSheet(sheetHostContext, container, occurrence);
      } else {
        await _showOccurrenceEditSheet(viewerContext, container, occurrence);
      }
    },
    onViewLocation: hasLocation
        ? (viewerContext) async {
            Navigator.of(viewerContext).pop();
            if (closeParentSheetOnAction && parentSheetContext != null) {
              popParentSheet();
              if (parentSheetContext.mounted) {
                parentSheetContext.go(
                  '${AppRoutes.map}?modo=foco&lat=${lat.toStringAsFixed(6)}'
                  '&lng=${lng.toStringAsFixed(6)}',
                );
              }
            } else {
              viewerContext.go(
                '${AppRoutes.map}?modo=foco&lat=${lat.toStringAsFixed(6)}'
                '&lng=${lng.toStringAsFixed(6)}',
              );
            }
          }
        : null,
    onConfirm: occurrence.status != 'confirmed'
        ? (viewerContext) async {
            await repository.updateOccurrence(
              occurrence.copyWith(status: 'confirmed'),
            );
            container.invalidate(occurrencesListProvider);
            schedulePopParentSheetAfterViewer();
            return true;
          }
        : null,
    confirmDialogTitle: 'Confirmar ocorrência?',
    confirmDialogMessage: 'Marcar esta ocorrência como confirmada?',
    onDelete: (viewerContext) async {
      await repository.softDeleteOccurrence(occurrence.id);
      container.invalidate(occurrencesListProvider);
      schedulePopParentSheetAfterViewer();
      return true;
    },
    deleteDialogTitle: 'Excluir ocorrência?',
    deleteDialogMessage: 'A ocorrência será ocultada e marcada para sync.',
  );
}

Future<void> _showOccurrenceEditSheet(
  BuildContext context,
  ProviderContainer container,
  Occurrence occurrence,
) {
  final repository = container.read(occurrenceRepositoryProvider);
  return showSoloForteSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.92,
      child: OccurrenceCreationSheet(
        latitude: occurrence.lat ?? 0,
        longitude: occurrence.long ?? 0,
        initialOccurrence: occurrence,
        onCancel: () => Navigator.of(sheetContext).pop(),
        onConfirm: (data) async {
          await repository.updateOccurrence(
            occurrence.copyWith(
              type: data.type,
              description: data.description,
              clientId: data.clientId,
              photoPath: data.photoPath,
              category: data.category,
              status: occurrence.status,
              cultivar: data.cultivar,
              dataPlantio: data.dataPlantio,
              estadioFenologico: data.estadioFenologico,
              tipoOcorrencia: data.tipoOcorrencia,
              amostraSolo: data.amostraSolo,
              recomendacoes: data.recomendacoes,
              metricasJson: data.metricasJson,
              nutrientesJson: data.nutrientesJson,
              categoriasJson: data.categoriasJson,
              notasCategoriasJson: data.notasCategoriasJson,
              fotosCategoriasJson: data.fotosCategoriasJson,
            ),
          );
          container.invalidate(occurrencesListProvider);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    ),
  );
}

Future<({String clientName, OccurrenceLocationNames location})>
    _occurrenceExportContext(WidgetRef ref, Occurrence occurrence) async {
  final clientName =
      await _occurrenceClienteNomeForExport(ref, occurrence.clientId);
  final location = await resolveOccurrenceLocationNames(
    clientId: occurrence.clientId,
    lat: occurrence.lat,
    lng: occurrence.long,
    visitSessionId: occurrence.visitSessionId,
    farmLookup: _tryReadContract(() => ref.read(iFarmLookupProvider)),
    fieldLookup: _tryReadContract(() => ref.read(iFieldLookupProvider)),
    visitSessionLookup: _tryReadContract(
      () => ref.read(visitSessionLookupProvider),
    ),
  );
  return (clientName: clientName, location: location);
}

T? _tryReadContract<T>(T Function() read) {
  try {
    return read();
  } catch (_) {
    return null;
  }
}

Future<String> _occurrenceClienteNomeForExport(
  WidgetRef ref,
  String? clientId,
) async {
  final id = clientId?.trim() ?? '';
  if (id.isEmpty) return '';
  final lookup = _tryReadContract(() => ref.read(clientLookupProvider));
  if (lookup == null) return '';
  try {
    final client = await lookup.findById(id);
    final name = client?.name.trim();
    if (name != null && name.isNotEmpty) return name;
  } catch (_) {}
  return '';
}

Future<void> openOccurrenceReportHtml(
  BuildContext context,
  WidgetRef ref,
  Occurrence occurrence, {
  bool closeParentSheetOnAction = false,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final bodyBuilder = ref.read(htmlReportViewerBodyBuilderProvider);
  try {
    final html = await buildOccurrenceReportHtml(ref, occurrence);
    if (!context.mounted) return;
    final ctx = await _occurrenceExportContext(ref, occurrence);
    final exportBaseName = ConsultoriaReportExportData.occurrenceFileBaseName(
      occurrence,
      clientName: ctx.clientName,
      farmName: ctx.location.fazenda,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HtmlReportViewer(
          title: 'Ocorrência ${RelatorioHtmlRenderer.shortId(occurrence.id)}',
          htmlContent: html,
          fileBaseName: exportBaseName,
          jsonData: ConsultoriaReportExportData.occurrenceJson(occurrence),
          csvData: ConsultoriaReportExportData.occurrenceCsv(occurrence),
          bodyBuilder: bodyBuilder,
          actions: occurrenceReportHtmlViewerActions(
            container,
            occurrence,
            closeParentSheetOnAction: closeParentSheetOnAction,
            parentSheetContext:
                closeParentSheetOnAction ? context : null,
          ),
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(e, action: 'Erro ao abrir relatório'),
          ),
        ),
      );
    }
  }
}

Future<void> exportOccurrenceReportHtml(
  BuildContext context,
  WidgetRef ref,
  Occurrence occurrence,
) async {
  try {
    final shareOrigin = resolveSharePositionOrigin(context);
    final html = await buildOccurrenceReportHtml(ref, occurrence);
    if (!context.mounted) return;
    final ctx = await _occurrenceExportContext(ref, occurrence);
    await const ReportExportService().export(
      ReportExportFormat.html,
      ReportExportPayload(
        title: 'Ocorrência ${RelatorioHtmlRenderer.shortId(occurrence.id)}',
        html: html,
        fileBaseName: ConsultoriaReportExportData.occurrenceFileBaseName(
          occurrence,
          clientName: ctx.clientName,
          farmName: ctx.location.fazenda,
        ),
        json: ConsultoriaReportExportData.occurrenceJson(occurrence),
        csv: ConsultoriaReportExportData.occurrenceCsv(occurrence),
      ),
      sharePositionOrigin: shareOrigin,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exportação iniciada.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingError(e, action: 'Erro ao exportar')),
        ),
      );
    }
  }
}

/// Botão "Exportar localização" (área visitada). A ação vem do host do mapa
/// por callback — o módulo não importa `lib/ui/`.
class OccurrenceDetailExportLocationButton extends StatelessWidget {
  final Occurrence occurrence;
  final bool isIos;
  final Color accentColor;
  final Future<void> Function(BuildContext context, Occurrence occurrence)
      onExportLocation;

  const OccurrenceDetailExportLocationButton({
    super.key,
    required this.occurrence,
    required this.isIos,
    required this.accentColor,
    required this.onExportLocation,
  });

  static bool eligible(
    Occurrence occurrence,
    Future<void> Function(BuildContext, Occurrence)? onExportLocation,
  ) {
    return onExportLocation != null &&
        isAreaVisitadaCategory(occurrence.category) &&
        occurrence.getCoordinates() != null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => onExportLocation(context, occurrence),
          style: isIos
              ? OutlinedButton.styleFrom(
                  foregroundColor: SoloForteSheetSkinIos.ghostText,
                  side: const BorderSide(
                    color: SoloForteSheetSkinIos.ghostBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      SoloForteSheetSkinIos.ghostRadius,
                    ),
                  ),
                )
              : null,
          icon: Icon(
            Icons.ios_share_outlined,
            size: 18,
            color: isIos ? SoloForteSheetSkinIos.iconStroke : accentColor,
          ),
          label: const Text('Exportar localização'),
        ),
      ),
    );
  }
}

/// Botões Abrir relatório / Exportar HTML no sheet de detalhe (mapa).
class OccurrenceDetailReportActionsRow extends ConsumerWidget {
  final Occurrence occurrence;
  final bool isIos;
  final bool closeParentSheetOnAction;

  const OccurrenceDetailReportActionsRow({
    super.key,
    required this.occurrence,
    required this.isIos,
    this.closeParentSheetOnAction = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iosButtonStyle = isIos
        ? OutlinedButton.styleFrom(
            foregroundColor: SoloForteSheetSkinIos.ghostText,
            side: const BorderSide(color: SoloForteSheetSkinIos.ghostBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                SoloForteSheetSkinIos.ghostRadius,
              ),
            ),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => openOccurrenceReportHtml(
                context,
                ref,
                occurrence,
                closeParentSheetOnAction: closeParentSheetOnAction,
              ),
              style: iosButtonStyle,
              child: const Text('Abrir relatório'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  exportOccurrenceReportHtml(context, ref, occurrence),
              style: iosButtonStyle,
              child: const Text('Exportar HTML'),
            ),
          ),
        ],
      ),
    );
  }
}
