import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/html_templates/html_report_viewer.dart';
import '../../../../core/html_templates/marketing_html_renderer.dart';
import '../../../../core/html_templates/ocorrencia_html_renderer.dart';
import '../../../../core/html_templates/propriedade_html_renderer.dart';
import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../../../core/html_templates/report_export_service.dart';
import '../../../../core/html_templates/visita_html_renderer.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../infra/consultoria_report_export_data.dart';
import '../models/relatorio_status.dart';
import '../models/relatorio_tecnico.dart';
import '../providers/relatorio_providers.dart' as tech;
import '../use_cases/publish_relatorio_use_case.dart';
import '../../publicacoes/providers/publicacao_providers.dart';
import '../../../settings/domain/entities/user_profile.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/presentation/providers/user_profile_provider.dart';

// Ocorrências — mesmo bounded context (consultoria/)
import '../../occurrences/presentation/controllers/occurrence_controller.dart';
import '../../occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import '../../occurrences/presentation/widgets/occurrence_detail_sheet.dart';
// hide SyncStatus para evitar conflito com o enum de relatorio.dart
import '../../occurrences/domain/occurrence.dart' hide SyncStatus;
import '../../../marketing/domain/entities/marketing_case.dart';
import '../../../marketing/presentation/providers/marketing_providers.dart';

part 'relatorios_consolidated_reports.dart';
part 'relatorios_shared_widgets.dart';

final _relatoriosTecnicosListProvider =
    FutureProvider.autoDispose<List<RelatorioTecnico>>((ref) async {
      return ref.watch(tech.relatorioRepositoryProvider).getAll();
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

/// Tela de Relatórios com duas seções de dados reais do SQLite local:
///
/// 1. Relatórios de Visita  → tabela técnica `relatorios`
/// 2. Ocorrências Registradas → [occurrencesListProvider]
class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // ── Seção 1: Relatórios de Visita ──────────────────────────
                  _RelatoriosSection(dateFormat: _dateFormat),
                  const SizedBox(height: 20),

                  // ── Seção 2: Ocorrências Registradas ───────────────────────
                  _OccurrenciasSection(dateFormat: _dateFormat),
                  const SizedBox(height: 20),

                  // ── Seção 3: Relatórios consolidados ───────────────────────
                  _ConsolidatedReportsSection(dateFormat: _dateFormat),
                  const SizedBox(height: 20),

                  // ── Seção 4: Marketing Cases ───────────────────────────────
                  _MarketingCasesReportsSection(dateFormat: _dateFormat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Relatórios',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO 1 — Relatórios de Visita
// ══════════════════════════════════════════════════════════════════════════════

class _RelatoriosSection extends ConsumerWidget {
  final DateFormat dateFormat;
  const _RelatoriosSection({required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatoriosAsync = ref.watch(_relatoriosTecnicosListProvider);

    return relatoriosAsync.when(
      data: (list) => _SectionContainer(
        title: 'Relatórios de Visita',
        count: list.length,
        emptyMessage: 'Nenhum relatório gerado ainda.',
        isEmpty: list.isEmpty,
        child: Column(
          children: list
              .map((r) => _RelatorioCard(relatorio: r, dateFormat: dateFormat))
              .toList(),
        ),
      ),
      loading: () => const _SectionLoading(title: 'Relatórios de Visita'),
      error: (e, stack) {
        debugPrint(
          '[RelatoriosScreen] relatoriosListProvider ERROR: $e\n$stack',
        );
        return _SectionError(
          title: 'Relatórios de Visita',
          onRetry: () => ref.invalidate(_relatoriosTecnicosListProvider),
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

    return InkWell(
      onTap: () => context.go('/consultoria/relatorios/${relatorio.id}'),
      borderRadius: BorderRadius.circular(12),
      child: _DataCard(
        leading: const Icon(Icons.description_outlined, size: 20),
        title: relatorio.title?.isNotEmpty == true
            ? relatorio.title!
            : relatorio.farmName,
        subtitle: relatorio.farmName,
        date: dateFormat.format(relatorio.createdAt.toLocal()),
        statusLabel: statusLabel,
        statusColor: statusColor,
        trailing: _AsyncActionMenu(
          tooltip: 'Ações do relatório',
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Ver detalhes')),
            const PopupMenuItem(
              value: 'html',
              child: Text('Pré-visualizar HTML'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(enabled: false, child: Text('Exportar dados')),
            const PopupMenuItem(value: 'export_pdf', child: Text('PDF')),
            const PopupMenuItem(value: 'export_html', child: Text('HTML')),
            const PopupMenuItem(value: 'export_json', child: Text('JSON')),
            const PopupMenuItem(value: 'export_csv', child: Text('CSV')),
            const PopupMenuDivider(),
            if (relatorio.status == RelatorioStatus.pendente_revisao)
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
            if (relatorio.status == RelatorioStatus.pendente_revisao)
              const PopupMenuItem(value: 'publish', child: Text('Publicar')),
            if (relatorio.status == RelatorioStatus.publicado)
              const PopupMenuItem(value: 'archive', child: Text('Arquivar')),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (value) => _handleAction(context, ref, value),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'view':
        context.go('/consultoria/relatorios/${relatorio.id}');
        return;
      case 'edit':
        context.go('/consultoria/relatorios/${relatorio.id}/edit');
        return;
      case 'html':
        await _openHtml(context);
        return;
      case 'export_pdf':
        await _export(context, ref, ReportExportFormat.pdf);
        return;
      case 'export_html':
        await _export(context, ref, ReportExportFormat.html);
        return;
      case 'export_json':
        await _export(context, ref, ReportExportFormat.json);
        return;
      case 'export_csv':
        await _export(context, ref, ReportExportFormat.csv);
        return;
      case 'publish':
        await _publish(context, ref);
        return;
      case 'archive':
        await _archive(context, ref);
        return;
      case 'delete':
        await _delete(context, ref);
        return;
    }
  }

  Future<void> _openHtml(BuildContext context) async {
    final html = await _buildHtml(null);
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
    final html = await _buildHtml(ref);
    final payload = ReportExportPayload(
      title: 'Relatório de Visita',
      html: html,
      fileBaseName: ConsultoriaReportExportData.reportFileBaseName(relatorio),
      json: ConsultoriaReportExportData.reportJson(relatorio),
      csv: ConsultoriaReportExportData.reportCsv(relatorio),
    );
    await const ReportExportService().export(format, payload);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exportação iniciada.')));
  }

  Future<String> _buildHtml(WidgetRef? ref) async {
    final clienteNome = ref == null
        ? relatorio.clientId
        : await _resolveClienteNome(ref);
    final publicacoesTitulos = ref == null
        ? const <String, String>{}
        : await _resolvePublicacoesTitulos(ref);
    final branding = await _resolveReportBrandingContext(
      ref,
      fallbackConsultantName: _resolveAgronomistNome(),
      fallbackConsultantRole: 'Consultoria',
    );
    return VisitaHtmlRenderer.render(
      relatorio: relatorio.toJson(),
      agronomistNome: branding.consultantName,
      clienteNome: clienteNome,
      publicacoesTitulos: publicacoesTitulos,
      reportBrandName: branding.brandName,
      reportLogoPath: branding.logoPath,
      consultantRole: branding.consultantRole,
    );
  }

  Future<String> _resolveClienteNome(WidgetRef ref) async {
    try {
      final client = await ref
          .read(clientLookupProvider)
          .findById(relatorio.clientId);
      final name = client?.name.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {
      // Lookup pode não estar registrado em testes isolados.
    }
    return relatorio.clientId;
  }

  Future<Map<String, String>> _resolvePublicacoesTitulos(WidgetRef ref) async {
    final titles = <String, String>{};
    for (final id in relatorio.publicacoesRefs) {
      try {
        final publicacao = await ref.read(
          publicacaoDetailProvider(id: id).future,
        );
        final title = publicacao?.titulo.trim();
        titles[id] = title != null && title.isNotEmpty ? title : id;
      } catch (_) {
        titles[id] = id;
      }
    }
    return titles;
  }

  String _resolveAgronomistNome() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final fullName = metadata['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    final name = metadata['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return relatorio.agronomistId;
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

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final confirm = await _confirm(
      context,
      title: 'Arquivar relatório?',
      message: 'O relatório será removido da fila ativa de revisão.',
      action: 'Arquivar',
    );
    if (confirm != true) return;
    await ref
        .read(tech.relatorioRepositoryProvider)
        .update(
          relatorio.copyWith(
            status: RelatorioStatus.arquivado,
            syncStatus: RelatorioSyncStatus.pending_sync,
          ),
        );
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
        return const Color(0xFF34C759);
      case RelatorioStatus.arquivado:
        return Colors.grey;
      case RelatorioStatus.pendente_revisao:
        return const Color(0xFFFF9500);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO 2 — Ocorrências Registradas
// ══════════════════════════════════════════════════════════════════════════════

class _OccurrenciasSection extends ConsumerWidget {
  final DateFormat dateFormat;
  const _OccurrenciasSection({required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occAsync = ref.watch(occurrencesListProvider);

    return occAsync.when(
      data: (list) => _SectionContainer(
        title: 'Ocorrências Registradas',
        count: list.length,
        emptyMessage: 'Nenhuma ocorrência registrada.',
        isEmpty: list.isEmpty,
        child: Column(
          children: list
              .map(
                (o) => _OccurrenciaCard(occurrence: o, dateFormat: dateFormat),
              )
              .toList(),
        ),
      ),
      loading: () => const _SectionLoading(title: 'Ocorrências Registradas'),
      error: (e, stack) {
        debugPrint(
          '[RelatoriosScreen] occurrencesListProvider ERROR: $e\n$stack',
        );
        return _SectionError(
          title: 'Ocorrências Registradas',
          onRetry: () => ref.refresh(occurrencesListProvider),
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
    final categoryLabel = occurrence.category ?? occurrence.type;

    return InkWell(
      onTap: () => OccurrenceDetailSheet.show(context, occurrence),
      borderRadius: BorderRadius.circular(12),
      child: _DataCard(
        leading: const Icon(Icons.warning_amber_rounded, size: 20),
        title: occurrence.type,
        subtitle: categoryLabel != occurrence.type ? categoryLabel : null,
        date: dateFormat.format(occurrence.createdAt.toLocal()),
        statusLabel: statusLabel,
        statusColor: statusColor,
        trailing: _AsyncActionMenu(
          tooltip: 'Ações da ocorrência',
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Ver detalhes')),
            const PopupMenuItem(
              value: 'html',
              child: Text('Pré-visualizar HTML'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(enabled: false, child: Text('Exportar dados')),
            const PopupMenuItem(value: 'export_pdf', child: Text('PDF')),
            const PopupMenuItem(value: 'export_html', child: Text('HTML')),
            const PopupMenuItem(value: 'export_json', child: Text('JSON')),
            const PopupMenuItem(value: 'export_csv', child: Text('CSV')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            if (occurrence.status != 'confirmed')
              const PopupMenuItem(value: 'confirm', child: Text('Confirmar')),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (value) => _handleAction(context, ref, value),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'view':
        await OccurrenceDetailSheet.show(context, occurrence);
        return;
      case 'html':
        await _openHtml(context, ref);
        return;
      case 'export_pdf':
        await _export(context, ref, ReportExportFormat.pdf);
        return;
      case 'export_html':
        await _export(context, ref, ReportExportFormat.html);
        return;
      case 'export_json':
        await _export(context, ref, ReportExportFormat.json);
        return;
      case 'export_csv':
        await _export(context, ref, ReportExportFormat.csv);
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
    final branding = await _resolveReportBrandingContext(
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
        ? const Color(0xFF34C759)
        : const Color(0xFFFF9500);
  }
}
