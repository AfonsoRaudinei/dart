part of 'relatorios_page.dart';

/// Aba Consolidados — Resumo + Histórico por produtor (clientId único).
class _ConsolidatedReportsSection extends ConsumerWidget {
  final DateFormat dateFormat;
  final String? selectedProducerClientId;
  final ValueChanged<String> onProducerSelected;

  const _ConsolidatedReportsSection({
    required this.dateFormat,
    required this.selectedProducerClientId,
    required this.onProducerSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatoriosAsync = ref.watch(_relatoriosTecnicosListProvider);

    if (relatoriosAsync.isLoading) {
      return const _SectionLoading(title: 'Relatórios Consolidados');
    }
    if (relatoriosAsync.hasError) {
      return _SectionError(
        title: 'Relatórios Consolidados',
        onRetry: () => ref.invalidate(_relatoriosTecnicosListProvider),
      );
    }

    final relatorios =
        relatoriosAsync.valueOrNull ?? const <RelatorioTecnico>[];
    final nowLabel = dateFormat.format(DateTime.now());
    final producerCounts =
        _producerCountsFromIds(relatorios.map((r) => r.clientId));
    final producerIds = producerCounts.keys.toList()..sort();
    final effectiveClientId = resolveRelatoriosProducerClientId(
      selectedClientId: selectedProducerClientId,
      routeClientId: _relatoriosRouteClienteId(context),
      producerIds: producerIds,
    );
    final scoped = producerIds.isEmpty
        ? relatorios
        : effectiveClientId == null
        ? const <RelatorioTecnico>[]
        : relatorios
            .where((report) => report.clientId == effectiveClientId)
            .toList();
    final hasProperty = scoped.any(
      (report) => report.farmName.trim().isNotEmpty,
    );
    final exportsEnabled = effectiveClientId != null && scoped.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InsetGroupHeader(title: 'Relatórios Consolidados', count: 2),
        if (relatorios.isEmpty)
          _PremiumEmptyState(
            message:
                'Sem dados para consolidar. Gere relatórios de visita na aba Visitas (via mapa).',
            ctaLabel: 'Abrir mapa',
            onCta: () => context.go(AppRoutes.map),
          )
        else ...[
          _relatoriosProducerSelectorBlock(
            context: context,
            producerIds: producerIds,
            itemCounts: producerCounts,
            effectiveClientId: effectiveClientId,
            onSelected: onProducerSelected,
          ),
          if (!exportsEnabled)
            _PremiumEmptyState(
              message: producerIds.length > 1
                  ? 'Selecione um produtor para consolidar visitas e exportar relatórios.'
                  : 'Nenhum relatório vinculado a produtor para consolidar.',
            )
          else
            Builder(
              builder: (context) {
                final clientId = effectiveClientId;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GeneratedReportCard(
                      eyebrow: 'Gerado sob demanda',
                      title: 'Resumo da Propriedade',
                      subtitle: _propertySubtitle(scoped),
                      date: nowLabel,
                      enabled: hasProperty,
                      buildPayload: () => _buildPropertySummaryPayload(
                        ref,
                        scoped,
                        clientId,
                      ),
                    ),
                    _GeneratedReportCard(
                      eyebrow: 'Gerado sob demanda',
                      title: 'Histórico de Visitas',
                      subtitle: '${scoped.length} visita(s)',
                      date: nowLabel,
                      enabled: scoped.isNotEmpty,
                      buildPayload: () => _buildVisitHistoryPayload(
                        ref,
                        scoped,
                        clientId,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _VisitHistoryTimeline(
                      relatorios: scoped,
                      dateFormat: dateFormat,
                    ),
                  ],
                );
              },
            ),
        ],
      ],
    );
  }

  String _propertySubtitle(List<RelatorioTecnico> relatorios) {
    final farms = relatorios.map((report) => report.farmName).toSet();
    final talhoes = relatorios
        .expand((report) => report.talhoes)
        .map((talhao) => talhao.talhaoId)
        .toSet();
    return '${farms.length} propriedade(s), ${talhoes.length} talhão(ões)';
  }
}

/// Timeline compacta do histórico de visitas (Consolidados).
class _VisitHistoryTimeline extends StatelessWidget {
  final List<RelatorioTecnico> relatorios;
  final DateFormat dateFormat;

  const _VisitHistoryTimeline({
    required this.relatorios,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = _sortRelatoriosByPeriodStart(relatorios);
    final items = sorted.take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            'Linha do tempo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.premiumTextSecondary,
            ),
          ),
        ),
        ...items.map((report) {
          final title = report.title?.isNotEmpty == true
              ? report.title!
              : report.farmName;
          final status = switch (report.status) {
            RelatorioStatus.publicado => 'Publicado',
            RelatorioStatus.arquivado => 'Arquivado',
            RelatorioStatus.pendente_revisao => 'Rascunho',
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: PremiumTokens.brandGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      color: const Color(0xFFE5E5EA),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.premiumTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${dateFormat.format(report.periodStart.toLocal())} · $status · ${report.farmName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.premiumTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
