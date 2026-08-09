part of 'relatorios_page.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SEÇÃO — Relatórios de Visita
// ══════════════════════════════════════════════════════════════════════════════

class _RelatoriosSection extends ConsumerStatefulWidget {
  final DateFormat dateFormat;
  const _RelatoriosSection({required this.dateFormat});

  @override
  ConsumerState<_RelatoriosSection> createState() => _RelatoriosSectionState();
}

class _RelatoriosSectionState extends ConsumerState<_RelatoriosSection> {
  String? _selectedClientId;

  void _selectProducer(String clientId) {
    if (_selectedClientId == clientId) return;
    setState(() => _selectedClientId = clientId);
  }

  @override
  Widget build(BuildContext context) {
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

        final producerCounts =
            _producerCountsFromIds(list.map((report) => report.clientId));
        final producerIds = producerCounts.keys.toList()..sort();
        final effectiveClientId = _selectedClientId ??
            (producerIds.length == 1 ? producerIds.first : null);
        final scoped = effectiveClientId == null
            ? const <RelatorioTecnico>[]
            : list
                .where((report) => report.clientId == effectiveClientId)
                .toList();
        final headerCount = effectiveClientId != null && producerIds.length > 1
            ? scoped.length
            : list.length;
        final visibleRelatorios = producerIds.length <= 1
            ? list
            : (effectiveClientId == null
                ? const <RelatorioTecnico>[]
                : scoped);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _InsetGroupHeader(
              title: 'Relatórios de Visita',
              count: headerCount,
            ),
            if (producerIds.length > 1) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'Produtor',
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
            if (producerIds.length > 1 && effectiveClientId == null)
              const _PremiumEmptyState(
                message:
                    'Selecione um produtor para visualizar relatórios de visita.',
              )
            else
              ...visibleRelatorios.map(
                (relatorio) => _RelatorioCard(
                  relatorio: relatorio,
                  dateFormat: widget.dateFormat,
                ),
              ),
            const SizedBox(height: kFabSafeArea),
          ],
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
