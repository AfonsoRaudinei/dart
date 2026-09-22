import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/contracts/i_occurrence_access_reader_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/html_templates/html_report_viewer.dart';
import '../../../../core/html_templates/ocorrencia_html_renderer.dart';
import '../../../../core/html_templates/propriedade_html_renderer.dart';
import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../../../core/html_templates/report_export_service.dart';
import '../../../../core/session/user_role.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../quick_photo/data/quick_photo_repository.dart';
import '../../quick_photo/domain/quick_photo_record.dart';
import '../../quick_photo/presentation/providers/quick_photo_list_provider.dart';
import '../../quick_photo/presentation/quick_photo_flow.dart';
import '../infra/consultoria_report_export_data.dart';
import '../infra/relatorio_visit_html_builder.dart';
import '../models/relatorio_status.dart';
import '../models/relatorio_tecnico.dart';
import '../providers/relatorio_providers.dart' as tech;
import '../use_cases/publish_relatorio_use_case.dart';
import '../../../settings/domain/entities/user_profile.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/presentation/providers/user_profile_provider.dart';

// Ocorrências — mesmo bounded context (consultoria/)
import '../../occurrences/presentation/controllers/occurrence_controller.dart';
import '../../occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import '../../occurrences/presentation/widgets/occurrence_photo_gallery.dart';
import '../../occurrences/domain/occurrence_photo_paths.dart';
import '../../relatorio_visita/data/image_storage_service.dart';
// hide SyncStatus para evitar conflito com o enum de relatorio.dart
import '../../occurrences/domain/occurrence.dart' hide SyncStatus;
import '../../../../core/contracts/marketing_case_reports_list_provider.dart';
import '../../../../core/contracts/i_marketing_case_reports_lookup_provider.dart';
import '../../../../core/contracts/marketing_case_report_snapshot.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

part 'relatorios_producer_helpers.dart';
part 'relatorios_generated_reports.dart';
part 'relatorios_marketing_reports.dart';
part 'relatorios_consolidated_reports.dart';
part 'relatorios_shared_widgets.dart';
part 'relatorios_visit_photos_section.dart';

/// Testes injetam corpo fake via override; produção permanece `null` (WebView).
final htmlReportViewerBodyBuilderProvider = Provider<WidgetBuilder?>(
  (ref) => null,
);

final _relatoriosTecnicosListProvider =
    FutureProvider.autoDispose<List<RelatorioTecnico>>((ref) async {
      final role = ref.watch(currentUserRoleProvider);
      final repo = ref.watch(tech.relatorioRepositoryProvider);
      if (!role.isProdutor) {
        return repo.getAll();
      }
      final authorized = await ref.watch(authorizedClientIdsProvider.future);
      return repo.getVisibleForAuthorizedClients(authorized);
    });

class _ReportBrandingContext {
  final String? brandName;
  final String? logoPath;
  final String consultantName;
  final String? consultantRole;

  const _ReportBrandingContext({
    required this.brandName,
    required this.logoPath,
    required this.consultantName,
    required this.consultantRole,
  });
}

Future<_ReportBrandingContext> _resolveReportBrandingContext(
  WidgetRef? ref, {
  required String fallbackConsultantName,
  String? fallbackConsultantRole,
}) async {
  if (ref == null) {
    return _ReportBrandingContext(
      brandName: null,
      logoPath: null,
      consultantName: fallbackConsultantName,
      consultantRole: fallbackConsultantRole,
    );
  }

  await ref.read(reportBrandingProvider.notifier).refreshRemote();
  final branding = ref.read(reportBrandingProvider);
  UserProfile? profile;
  try {
    profile = await ref.read(currentUserProfileProvider.future);
  } catch (_) {
    profile = null;
  }

  final consultantName = (profile?.fullName?.trim().isNotEmpty ?? false)
      ? profile!.fullName!.trim()
      : fallbackConsultantName;
  final consultantRole = (profile?.role?.trim().isNotEmpty ?? false)
      ? profile!.role!.trim()
      : fallbackConsultantRole;

  return _ReportBrandingContext(
    brandName: branding.brandName,
    logoPath: branding.logoPath,
    consultantName: consultantName,
    consultantRole: consultantRole,
  );
}

/// Tela de Relatórios — Premium iOS com segmentos tipados.
///
/// Segmentos: Visitas | Ocorrências | Marketing | Consolidados
/// (Mídia oculta 17/08/2026 — reativar com o relatório HTML de marketing)
/// Marketing = publicações/cases (ADR-050), incl. não gerados (rascunho).
class RelatoriosScreen extends ConsumerStatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  ConsumerState<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends ConsumerState<RelatoriosScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  _RelatoriosSegment _segment = _RelatoriosSegment.gerados;

  void _selectSegment(_RelatoriosSegment value) {
    if (_segment == value) return;
    HapticFeedback.selectionClick();
    setState(() => _segment = value);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.premiumBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Relatórios',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.37,
                  color: context.premiumTextPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _RelatoriosSegmentBar(
                selected: _segment,
                onSelected: _selectSegment,
              ),
            ),
            Expanded(child: _buildSegmentBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentBody() {
    switch (_segment) {
      case _RelatoriosSegment.visitas:
        return _RelatoriosSection(dateFormat: _dateFormat);
      case _RelatoriosSegment.ocorrencias:
        return _OccurrenciasSection(dateFormat: _dateFormat);
      case _RelatoriosSegment.gerados:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _MarketingCasesReportsSection(dateFormat: _dateFormat),
            const SizedBox(height: kFabSafeArea),
          ],
        );
      case _RelatoriosSegment.consolidados:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _ConsolidatedReportsSection(dateFormat: _dateFormat),
            const SizedBox(height: kFabSafeArea),
          ],
        );
      case _RelatoriosSegment.midia:
        return _VisitPhotosSection(dateFormat: _dateFormat);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO — Relatórios de Visita
// ══════════════════════════════════════════════════════════════════════════════

class _RelatoriosSection extends ConsumerWidget {
  final DateFormat dateFormat;
  const _RelatoriosSection({required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatoriosAsync = ref.watch(_relatoriosTecnicosListProvider);

    return relatoriosAsync.when(
      data: (list) {
        final clienteId =
            GoRouterState.of(context).uri.queryParameters['clienteId'];
        final visible = clienteId == null || clienteId.isEmpty
            ? list
            : list.where((relatorio) => relatorio.clientId == clienteId).toList();
        if (visible.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const _InsetGroupHeader(title: 'Relatórios de Visita', count: 0),
              _PremiumEmptyState(
                message:
                    'Nenhum relatório de visita ainda. Finalize uma visita no mapa para gerar o relatório técnico.',
                ctaLabel: 'Abrir mapa',
                onCta: () => context.go(AppRoutes.map),
              ),
              const SizedBox(height: kFabSafeArea),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: visible.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _InsetGroupHeader(
                title: 'Relatórios de Visita',
                count: visible.length,
              );
            }
            if (index == visible.length + 1) {
              return const SizedBox(height: kFabSafeArea);
            }
            return _RelatorioCard(
              relatorio: visible[index - 1],
              dateFormat: dateFormat,
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: _SectionLoading(title: 'Relatórios de Visita'),
      ),
      error: (e, stack) {
        AppLogger.error(
          'relatoriosListProvider ERROR',
          tag: 'RelatoriosScreen',
          error: e,
          stackTrace: stack,
        );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _SectionError(
            title: 'Relatórios de Visita',
            onRetry: () => ref.invalidate(_relatoriosTecnicosListProvider),
          ),
        );
      },
    );
  }
}

class _RelatorioCard extends ConsumerStatefulWidget {
  final RelatorioTecnico relatorio;
  final DateFormat dateFormat;

  const _RelatorioCard({required this.relatorio, required this.dateFormat});

  @override
  ConsumerState<_RelatorioCard> createState() => _RelatorioCardState();
}

class _RelatorioCardState extends ConsumerState<_RelatorioCard> {
  HtmlReportViewerActions _visitViewerActions(ProviderContainer container) {
    final relatorio = widget.relatorio;
    final isDraft = relatorio.status == RelatorioStatus.pendente_revisao;
    final repository = container.read(tech.relatorioRepositoryProvider);
    return HtmlReportViewerActions(
      onEdit: isDraft
          ? (viewerContext) async {
              Navigator.of(viewerContext).pop();
              viewerContext.go('/consultoria/relatorios/${relatorio.id}/edit');
            }
          : null,
      onPublish: isDraft
          ? (viewerContext) async {
              await container.read(publishRelatorioProvider(relatorio.id).future);
              container.invalidate(_relatoriosTecnicosListProvider);
              return true;
            }
          : null,
      publishDialogTitle: 'Publicar relatório?',
      publishDialogMessage: 'O relatório ficará marcado como publicado.',
      onDelete: (viewerContext) async {
        await repository.softDelete(relatorio.id);
        container.invalidate(_relatoriosTecnicosListProvider);
        return true;
      },
      deleteDialogTitle: 'Excluir relatório?',
      deleteDialogMessage: 'A exclusão é lógica e será sincronizada depois.',
    );
  }

  Future<void> _openHtml(BuildContext context) async {
    final relatorio = widget.relatorio;
    final container = ProviderScope.containerOf(context, listen: false);
    final bodyBuilder = ref.read(htmlReportViewerBodyBuilderProvider);
    try {
      final html = await buildRelatorioVisitHtml(ref, relatorio);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HtmlReportViewer(
            title: 'Relatório de Visita',
            htmlContent: html,
            fileBaseName: ConsultoriaReportExportData.reportFileBaseName(
              relatorio,
            ),
            jsonData: ConsultoriaReportExportData.reportJson(relatorio),
            csvData: ConsultoriaReportExportData.reportCsv(relatorio),
            bodyBuilder: bodyBuilder,
            actions: _visitViewerActions(container),
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

  @override
  Widget build(BuildContext context) {
    final relatorio = widget.relatorio;
    final statusLabel = _statusLabel(relatorio.status);
    final statusColor = _statusColor(relatorio.status);
    final title = relatorio.title?.isNotEmpty == true
        ? relatorio.title!
        : relatorio.farmName;

    return _AsyncDataCard(
      eyebrow: 'Visita técnica',
      title: title,
      subtitle: title == relatorio.farmName ? null : relatorio.farmName,
      date: widget.dateFormat.format(relatorio.createdAt.toLocal()),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTapAsync: () => _openHtml(context),
    );
  }

  String _statusLabel(RelatorioStatus status) {
    switch (status) {
      case RelatorioStatus.pendente_revisao:
        return 'Rascunho';
      case RelatorioStatus.publicado:
        return 'Publicado';
      case RelatorioStatus.arquivado:
        return 'Arquivado';
    }
  }

  Color _statusColor(RelatorioStatus status) {
    switch (status) {
      case RelatorioStatus.publicado:
        return PremiumTokens.brandGreen;
      case RelatorioStatus.arquivado:
        return Colors.grey;
      case RelatorioStatus.pendente_revisao:
        return const Color(0xFFFF9500);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO — Ocorrências Registradas
// ══════════════════════════════════════════════════════════════════════════════

class _OccurrenciasSection extends ConsumerStatefulWidget {
  final DateFormat dateFormat;
  const _OccurrenciasSection({required this.dateFormat});

  @override
  ConsumerState<_OccurrenciasSection> createState() =>
      _OccurrenciasSectionState();
}

class _OccurrenciasSectionState extends ConsumerState<_OccurrenciasSection> {
  String? _selectedClientId;

  void _selectProducer(String clientId) {
    if (_selectedClientId == clientId) return;
    setState(() => _selectedClientId = clientId);
  }

  @override
  Widget build(BuildContext context) {
    final occAsync = ref.watch(occurrencesListProvider);

    return occAsync.when(
      data: (list) {
        final nowLabel = widget.dateFormat.format(DateTime.now());
        final producerCounts =
            _producerCountsFromIds(list.map((o) => o.clientId));
        final producerIds = producerCounts.keys.toList()..sort();
        final routeClientId =
            GoRouterState.of(context).uri.queryParameters['clienteId'];
        final effectiveClientId = _selectedClientId ??
            (routeClientId != null && routeClientId.isNotEmpty
                ? routeClientId
                : (producerIds.length == 1 ? producerIds.first : null));
        final scoped = effectiveClientId == null
            ? const <Occurrence>[]
            : list
                .where((occurrence) => occurrence.clientId == effectiveClientId)
                .toList();
        final exportEnabled = effectiveClientId != null && scoped.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _InsetGroupHeader(
              title: 'Ocorrências Registradas',
              count: list.length,
            ),
            if (list.isNotEmpty && producerIds.isNotEmpty) ...[
              if (producerIds.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    'Produtor (exportação)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.premiumTextSecondary,
                    ),
                  ),
                ),
                _RelatoriosProducerSelector(
                  producerIds: producerIds,
                  itemCounts: producerCounts,
                  selectedClientId: effectiveClientId,
                  onSelected: _selectProducer,
                ),
                const SizedBox(height: 12),
              ],
              _GeneratedReportCard(
                eyebrow: 'Exportar lista',
                title: 'Lista de Ocorrências',
                subtitle: exportEnabled
                    ? '${scoped.length} ocorrência(s)'
                    : producerIds.length > 1
                    ? 'Selecione um produtor'
                    : '${list.length} ocorrência(s)',
                date: nowLabel,
                enabled: exportEnabled,
                buildPayload: () => _buildOccurrenceListPayload(
                  ref,
                  scoped,
                  effectiveClientId!,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (list.isEmpty)
              _PremiumEmptyState(
                message:
                    'Nenhuma ocorrência registrada. Crie ocorrências no mapa para listar e exportar aqui.',
                ctaLabel: 'Abrir mapa',
                onCta: () => context.go(AppRoutes.map),
              )
            else
              ...list.map(
                (occurrence) => _OccurrenciaCard(
                  occurrence: occurrence,
                  dateFormat: widget.dateFormat,
                ),
              ),
            const SizedBox(height: kFabSafeArea),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: _SectionLoading(title: 'Ocorrências Registradas'),
      ),
      error: (e, stack) {
        AppLogger.error(
          'occurrencesListProvider ERROR',
          tag: 'RelatoriosScreen',
          error: e,
          stackTrace: stack,
        );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _SectionError(
            title: 'Ocorrências Registradas',
            onRetry: () => ref.refresh(occurrencesListProvider),
          ),
        );
      },
    );
  }
}

class _OccurrenciaCard extends ConsumerStatefulWidget {
  final Occurrence occurrence;
  final DateFormat dateFormat;

  const _OccurrenciaCard({required this.occurrence, required this.dateFormat});

  @override
  ConsumerState<_OccurrenciaCard> createState() => _OccurrenciaCardState();
}

class _OccurrenciaCardState extends ConsumerState<_OccurrenciaCard> {
  HtmlReportViewerActions _occurrenceViewerActions(ProviderContainer container) {
    final occurrence = widget.occurrence;
    final repository = container.read(occurrenceRepositoryProvider);
    final lat = occurrence.lat;
    final lng = occurrence.long;
    final hasLocation = lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        !(lat == 0 && lng == 0);

    return HtmlReportViewerActions(
      onEdit: (viewerContext) async {
        Navigator.of(viewerContext).pop();
        await _showEditSheet(viewerContext, container, occurrence);
      },
      onViewLocation: hasLocation
          ? (viewerContext) async {
              Navigator.of(viewerContext).pop();
              viewerContext.go(
                '${AppRoutes.map}?modo=foco&lat=${lat.toStringAsFixed(6)}'
                '&lng=${lng.toStringAsFixed(6)}',
              );
            }
          : null,
      onConfirm: occurrence.status != 'confirmed'
          ? (viewerContext) async {
              await repository.updateOccurrence(
                occurrence.copyWith(status: 'confirmed'),
              );
              container.invalidate(occurrencesListProvider);
              return true;
            }
          : null,
      confirmDialogTitle: 'Confirmar ocorrência?',
      confirmDialogMessage: 'Marcar esta ocorrência como confirmada?',
      onDelete: (viewerContext) async {
        await repository.softDeleteOccurrence(occurrence.id);
        container.invalidate(occurrencesListProvider);
        return true;
      },
      deleteDialogTitle: 'Excluir ocorrência?',
      deleteDialogMessage: 'A ocorrência será ocultada e marcada para sync.',
    );
  }

  Future<void> _openHtml(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final bodyBuilder = ref.read(htmlReportViewerBodyBuilderProvider);
    final occurrence = widget.occurrence;
    try {
      final html = await _buildHtml(ref, occurrence);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HtmlReportViewer(
            title: 'Ocorrência ${RelatorioHtmlRenderer.shortId(occurrence.id)}',
            htmlContent: html,
            fileBaseName: ConsultoriaReportExportData.occurrenceFileBaseName(
              occurrence,
            ),
            jsonData: ConsultoriaReportExportData.occurrenceJson(occurrence),
            csvData: ConsultoriaReportExportData.occurrenceCsv(occurrence),
            bodyBuilder: bodyBuilder,
            actions: _occurrenceViewerActions(container),
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

  Widget? _occurrenceCardLeading(Occurrence occurrence) {
    if (allPhotoPaths(occurrence).isEmpty) return null;
    final category = OccurrenceCategory.fromString(occurrence.category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: OccurrenceCoverThumbnail(
        occurrence: occurrence,
        width: 60,
        height: 80,
        fallback: Container(
          width: 60,
          height: 80,
          color: category.markerColor.withValues(alpha: 0.12),
          alignment: Alignment.center,
          child: Text(category.emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final occurrence = widget.occurrence;
    return _AsyncDataCard(
      leading: _occurrenceCardLeading(occurrence),
      eyebrow: 'Ocorrência',
      title: _occurrenceCardTitle(occurrence),
      subtitle: _occurrenceCardSubtitle(occurrence),
      date: widget.dateFormat.format(occurrence.createdAt.toLocal()),
      statusLabel: _occStatusLabel(occurrence.status),
      statusColor: _occStatusColor(occurrence.status),
      onTapAsync: () => _openHtml(context),
    );
  }

  Future<String> _buildHtml(WidgetRef ref, Occurrence occurrence) async {
    final data = occurrence.toMap();
    final cover = coverPhotoPath(occurrence);
    data['foto_base64'] =
        await RelatorioHtmlRenderer.photoPathToBase64(cover) ?? '';
    if (occurrence.fotosCategoriasJson != null) {
      data['fotos_categorias_json'] = encodeFotosCategoriasJson(
        occurrence.fotosCategoriasJson,
        ImageStorageService().toStoredPath,
      );
    }
    if (cover != null) {
      data['photo_path'] = ImageStorageService().toStoredPath(cover);
    }
    final branding = await resolveReportBrandingContext(
      ref,
      fallbackConsultantName: 'Equipe técnica',
      fallbackConsultantRole: 'Consultoria',
    );
    return OcorrenciaHtmlRenderer.renderDetalhe(
      data,
      reportBrandName: branding.brandName,
      reportLogoPath: branding.logoPath,
      consultantName: branding.consultantName,
      consultantRole: branding.consultantRole,
    );
  }

  Future<void> _showEditSheet(
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

  String _occStatusLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'draft':
      default:
        return 'Rascunho';
    }
  }

  Color _occStatusColor(String? status) {
    return status == 'confirmed'
        ? PremiumTokens.brandGreen
        : const Color(0xFFFF9500);
  }
}
