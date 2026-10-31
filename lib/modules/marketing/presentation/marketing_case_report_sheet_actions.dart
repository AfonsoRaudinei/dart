import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/i_marketing_case_reports_lookup_provider.dart';
import '../../../core/contracts/marketing_case_report_snapshot.dart';
import '../../../core/html_templates/html_report_viewer.dart';
import '../../../core/html_templates/report_export_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/ui/sheets/sheet_tokens.dart';
import '../../../core/utils/share_position.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../settings/domain/entities/user_profile.dart';
import '../../settings/presentation/providers/settings_providers.dart';
import '../../settings/presentation/providers/user_profile_provider.dart';
import '../domain/entities/marketing_case.dart';
import '../domain/enums/marketing_case_status.dart';

Future<MarketingCaseReportExportBundle> _buildBundle(
  WidgetRef ref,
  MarketingCase marketingCase,
) async {
  await ref.read(reportBrandingProvider.notifier).refreshRemote();
  final branding = ref.read(reportBrandingProvider);
  UserProfile? profile;
  try {
    profile = await ref.read(currentUserProfileProvider.future);
  } catch (_) {
    profile = null;
  }

  final fallbackName = marketingCase.nomeVendedor ?? 'Equipe técnica';
  const fallbackRole = 'Consultoria';
  final consultantName = (profile?.fullName?.trim().isNotEmpty ?? false)
      ? profile!.fullName!.trim()
      : fallbackName;
  final consultantRole = (profile?.role?.trim().isNotEmpty ?? false)
      ? profile!.role!.trim()
      : fallbackRole;

  return ref.read(marketingCaseReportsLookupProvider).buildExportBundle(
        marketingCase.id,
        fallbackConsultantName: fallbackName,
        fallbackConsultantRole: fallbackRole,
        reportBrandName: branding.brandName,
        reportLogoPath: branding.logoPath,
        consultantName: consultantName,
        consultantRole: consultantRole,
      );
}

HtmlReportViewerActions marketingCaseReportViewerActions(
  ProviderContainer container,
  MarketingCase marketingCase, {
  bool closeParentSheetOnAction = false,
  BuildContext? parentSheetContext,
}) {
  final lookup = container.read(marketingCaseReportsLookupProvider);
  final lat = marketingCase.lat;
  final lng = marketingCase.lng;
  final hasLocation =
      lat.isFinite && lng.isFinite && !(lat == 0 && lng == 0);
  final isDraft = marketingCase.status == MarketingCaseStatus.draft;

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
        await lookup.showEditSheet(sheetHostContext, marketingCase.id);
      } else {
        await lookup.showEditSheet(viewerContext, marketingCase.id);
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
    onPublish: isDraft
        ? (viewerContext) async {
            final published = await lookup.publishDraftCase(
              viewerContext,
              marketingCase.id,
            );
            if (published && viewerContext.mounted) {
              ScaffoldMessenger.of(viewerContext).showSnackBar(
                const SnackBar(content: Text('Case publicado com sucesso!')),
              );
              schedulePopParentSheetAfterViewer();
            }
            return published;
          }
        : null,
    publishDialogTitle: 'Publicar case?',
    publishDialogMessage: 'O case será publicado no mapa conforme seu plano.',
    onDelete: (viewerContext) async {
      await lookup.deleteCase(marketingCase.id);
      schedulePopParentSheetAfterViewer();
      return true;
    },
    deleteDialogTitle: 'Excluir publicação?',
    deleteDialogMessage:
        'A publicação será removida da lista e marcada para sincronização.',
  );
}

Future<void> openMarketingCaseReportHtml(
  BuildContext context,
  WidgetRef ref,
  MarketingCase marketingCase, {
  bool closeParentSheetOnAction = false,
  BuildContext? parentSheetContext,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final bodyBuilder = ref.read(htmlReportViewerBodyBuilderProvider);
  try {
    final bundle = await _buildBundle(ref, marketingCase);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HtmlReportViewer(
          title: bundle.title,
          htmlContent: bundle.html,
          fileBaseName: bundle.fileBaseName,
          jsonData: bundle.json,
          csvData: bundle.csv,
          bodyBuilder: bodyBuilder,
          actions: marketingCaseReportViewerActions(
            container,
            marketingCase,
            closeParentSheetOnAction: closeParentSheetOnAction,
            parentSheetContext: closeParentSheetOnAction
                ? (parentSheetContext ?? context)
                : null,
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

Future<void> exportMarketingCaseReportHtml(
  BuildContext context,
  WidgetRef ref,
  MarketingCase marketingCase,
) async {
  try {
    final shareOrigin = resolveSharePositionOrigin(context);
    final bundle = await _buildBundle(ref, marketingCase);
    if (!context.mounted) return;
    await const ReportExportService().export(
      ReportExportFormat.html,
      ReportExportPayload(
        title: bundle.title,
        html: bundle.html,
        fileBaseName: bundle.fileBaseName,
        json: bundle.json,
        csv: bundle.csv,
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

/// Botões Abrir relatório / Exportar HTML no sheet do pin (mapa).
class MarketingCaseReportActionsRow extends ConsumerWidget {
  final MarketingCase marketingCase;
  final bool isIos;
  final bool closeParentSheetOnAction;

  const MarketingCaseReportActionsRow({
    super.key,
    required this.marketingCase,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => openMarketingCaseReportHtml(
                context,
                ref,
                marketingCase,
                closeParentSheetOnAction: closeParentSheetOnAction,
                parentSheetContext: context,
              ),
              style: iosButtonStyle,
              child: const Text('Abrir relatório'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  exportMarketingCaseReportHtml(context, ref, marketingCase),
              style: iosButtonStyle,
              child: const Text('Exportar HTML'),
            ),
          ),
        ],
      ),
    );
  }
}
