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
import '../../../../core/utils/share_position.dart';
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
import '../../occurrences/presentation/widgets/occurrence_detail_sheet.dart';
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
/// Segmentos: Visitas | Ocorrências | Gerados | Consolidados | Mídia
/// Gerados = publicações de Marketing (ADR-050). Consolidados = exports on-demand.
class RelatoriosScreen extends ConsumerStatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  ConsumerState<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends ConsumerState<RelatoriosScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  _RelatoriosSegment _segment = _RelatoriosSegment.visitas;

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
        if (list.isEmpty) {
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
          itemCount: list.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _InsetGroupHeader(
                title: 'Relatórios de Visita',
                count: list.length,
              );
            }
            if (index == list.length + 1) {
              return const SizedBox(height: kFabSafeArea);
            }
            return _RelatorioCard(
              relatorio: list[index - 1],
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

class _RelatorioCard extends ConsumerWidget {
  final RelatorioTecnico relatorio;
  final DateFormat dateFormat;

  const _RelatorioCard({required this.relatorio, required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLabel = _statusLabel(relatorio.status);
    final statusColor = _statusColor(relatorio.status);
    final title = relatorio.title?.isNotEmpty == true
        ? relatorio.title!
        : relatorio.farmName;

    return _DataCard(
      eyebrow: 'Visita técnica',
      title: title,
      subtitle: title == relatorio.farmName ? null : relatorio.farmName,
      date: dateFormat.format(relatorio.createdAt.toLocal()),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: () => context.go('/consultoria/relatorios/${relatorio.id}'),
      trailing: _AsyncActionMenu(
        tooltip: 'Ações do relatório',
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'html',
            child: Text('Pré-visualizar HTML'),
          ),
          const PopupMenuItem(value: 'export', child: Text('Exportar')),
          if (relatorio.status == RelatorioStatus.pendente_revisao)
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
          if (relatorio.status == RelatorioStatus.pendente_revisao)
            const PopupMenuItem(value: 'publish', child: Text('Publicar')),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
        onSelected: (value) => _handleAction(context, ref, value),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'edit':
        context.go('/consultoria/relatorios/${relatorio.id}/edit');
        return;
      case 'html':
        await _openHtml(context, ref);
        return;
      case 'export':
        await _export(context, ref, ReportExportFormat.html);
        return;
      case 'publish':
        await _publish(context, ref);
        return;
      case 'delete':
        await _delete(context, ref);
        return;
    }
  }

  Future<void> _openHtml(BuildContext context, WidgetRef ref) async {
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
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ReportExportFormat format,
  ) async {
    final shareOrigin = resolveSharePositionOrigin(context);
    final html = await buildRelatorioVisitHtml(ref, relatorio);
    final payload = ReportExportPayload(
      title: 'Relatório de Visita',
      html: html,
      fileBaseName: ConsultoriaReportExportData.reportFileBaseName(relatorio),
      json: ConsultoriaReportExportData.reportJson(relatorio),
      csv: ConsultoriaReportExportData.reportCsv(relatorio),
    );
    await const ReportExportService().export(
      format,
      payload,
      sharePositionOrigin: shareOrigin,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exportação iniciada.')));
  }

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    final confirm = await _confirm(
      context,
      title: 'Publicar relatório?',
      message: 'O relatório ficará marcado como publicado.',
      action: 'Publicar',
    );
    if (confirm != true) return;
    await ref.read(publishRelatorioProvider(relatorio.id).future);
    ref.invalidate(_relatoriosTecnicosListProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await _confirm(
      context,
      title: 'Excluir relatório?',
      message: 'A exclusão é lógica e será sincronizada depois.',
      action: 'Excluir',
      destructive: true,
    );
    if (confirm != true) return;
    await ref.read(tech.relatorioRepositoryProvider).softDelete(relatorio.id);
    ref.invalidate(_relatoriosTecnicosListProvider);
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
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
        final effectiveClientId = _selectedClientId ??
            (producerIds.length == 1 ? producerIds.first : null);
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

class _OccurrenciaCard extends ConsumerWidget {
  final Occurrence occurrence;
  final DateFormat dateFormat;

  const _OccurrenciaCard({required this.occurrence, required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLabel = _occStatusLabel(occurrence.status);
    final statusColor = _occStatusColor(occurrence.status);

    return _DataCard(
      eyebrow: 'Ocorrência',
      title: _occurrenceCardTitle(occurrence),
      subtitle: _occurrenceCardSubtitle(occurrence),
      date: dateFormat.format(occurrence.createdAt.toLocal()),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: () => OccurrenceDetailSheet.show(
        context,
        occurrence,
        backRoute: AppRoutes.reports,
      ),
      trailing: _AsyncActionMenu(
        tooltip: 'Ações da ocorrência',
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'html',
            child: Text('Pré-visualizar HTML'),
          ),
          const PopupMenuItem(value: 'export', child: Text('Exportar')),
          const PopupMenuItem(value: 'edit', child: Text('Editar')),
          if (occurrence.status != 'confirmed')
            const PopupMenuItem(value: 'confirm', child: Text('Confirmar')),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
        onSelected: (value) => _handleAction(context, ref, value),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'html':
        await _openHtml(context, ref);
        return;
      case 'export':
        await _export(context, ref, ReportExportFormat.html);
        return;
      case 'edit':
        await _showEditSheet(context, ref);
        return;
      case 'confirm':
        await ref
            .read(occurrenceRepositoryProvider)
            .updateOccurrence(occurrence.copyWith(status: 'confirmed'));
        ref.invalidate(occurrencesListProvider);
        return;
      case 'delete':
        await _delete(context, ref);
        return;
    }
  }

  Future<void> _openHtml(BuildContext context, WidgetRef ref) async {
    final html = await _buildHtml(ref);
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
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ReportExportFormat format,
  ) async {
    final shareOrigin = resolveSharePositionOrigin(context);
    final html = await _buildHtml(ref);
    await const ReportExportService().export(
      format,
      ReportExportPayload(
        title: 'Ocorrência ${RelatorioHtmlRenderer.shortId(occurrence.id)}',
        html: html,
        fileBaseName: ConsultoriaReportExportData.occurrenceFileBaseName(
          occurrence,
        ),
        json: ConsultoriaReportExportData.occurrenceJson(occurrence),
        csv: ConsultoriaReportExportData.occurrenceCsv(occurrence),
      ),
      sharePositionOrigin: shareOrigin,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exportação iniciada.')));
  }

  Future<String> _buildHtml(WidgetRef ref) async {
    final data = occurrence.toMap();
    data['foto_base64'] =
        await RelatorioHtmlRenderer.photoPathToBase64(occurrence.photoPath) ??
        '';
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

  Future<void> _showEditSheet(BuildContext context, WidgetRef ref) {
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
            await ref
                .read(occurrenceRepositoryProvider)
                .updateOccurrence(
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
            ref.invalidate(occurrencesListProvider);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ocorrência?'),
        content: const Text('A ocorrência será ocultada e marcada para sync.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref
        .read(occurrenceRepositoryProvider)
        .softDeleteOccurrence(occurrence.id);
    ref.invalidate(occurrencesListProvider);
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
