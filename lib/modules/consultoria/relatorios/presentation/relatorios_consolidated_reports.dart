part of 'relatorios_page.dart';

/// Aba Consolidados — Resumo, Histórico e combinação cronológica por produtor.
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
    final occurrencesAsync = ref.watch(occurrencesListProvider);
    final marketingAsync = ref.watch(marketingCaseReportsListProvider);

    if (relatoriosAsync.isLoading && !relatoriosAsync.hasValue) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: const [
          _SectionLoading(title: 'Relatórios Consolidados'),
          SizedBox(height: kFabSafeArea),
        ],
      );
    }
    if (relatoriosAsync.hasError && !relatoriosAsync.hasValue) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _SectionError(
            title: 'Relatórios Consolidados',
            onRetry: () => ref.invalidate(_relatoriosTecnicosListProvider),
          ),
          const SizedBox(height: kFabSafeArea),
        ],
      );
    }

    final relatorios =
        relatoriosAsync.valueOrNull ?? const <RelatorioTecnico>[];
    final allOccurrences =
        occurrencesAsync.valueOrNull ?? const <Occurrence>[];
    final allMarketing =
        marketingAsync.valueOrNull ?? const <MarketingCaseReportSnapshot>[];
    final nowLabel = dateFormat.format(DateTime.now());
    final producerCounts = _producerCountsFromIds([
      ...relatorios.map((r) => r.clientId),
      ...allOccurrences.map((o) => o.clientId),
      ...allMarketing.map((c) => c.clientId),
    ]);
    final producerIds = producerCounts.keys.toList()..sort();
    final effectiveClientId = resolveRelatoriosProducerClientId(
      selectedClientId: selectedProducerClientId,
      routeClientId: _relatoriosRouteClienteId(context),
      producerIds: producerIds,
    );
    final scopedVisits = producerIds.isEmpty
        ? relatorios
        : effectiveClientId == null
        ? const <RelatorioTecnico>[]
        : relatorios
            .where((report) => report.clientId == effectiveClientId)
            .toList();
    final scopedOccurrences = effectiveClientId == null
        ? const <Occurrence>[]
        : _sortOccurrencesByCreatedAt(
            allOccurrences
                .where((o) => o.clientId == effectiveClientId)
                .toList(),
          );
    final scopedMarketing = effectiveClientId == null
        ? const <MarketingCaseReportSnapshot>[]
        : allMarketing
            .where((item) => item.clientId == effectiveClientId)
            .toList();
    final hasProperty = scopedVisits.any(
      (report) => report.farmName.trim().isNotEmpty,
    );
    final hasAnySource =
        relatorios.isNotEmpty ||
        allOccurrences.isNotEmpty ||
        allMarketing.isNotEmpty;
    final needsProducerPick =
        producerIds.length > 1 && effectiveClientId == null;
    final combinedEvents = effectiveClientId == null
        ? const <_CombinedReportEvent>[]
        : _combinedEventsForProducer(
            visits: scopedVisits,
            occurrences: scopedOccurrences,
            marketing: scopedMarketing,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const _InsetGroupHeader(title: 'Relatórios Consolidados', count: 3),
        if (!hasAnySource)
          _PremiumEmptyState(
            message:
                'Sem dados para consolidar. Gere relatórios de visita, ocorrência ou marketing no mapa.',
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
          if (needsProducerPick)
            const _PremiumEmptyState(
              message:
                  'Selecione um produtor para consolidar visitas e combinar relatórios.',
            )
          else if (effectiveClientId == null)
            const _PremiumEmptyState(
              message: 'Nenhum relatório vinculado a produtor para consolidar.',
            )
          else ...[
            _GeneratedReportCard(
              leading: _relatoriosReportIconBadge(
                icon: SFIcons.business,
                accent: const Color(0xFF2C5564),
              ),
              eyebrow: 'Gerado sob demanda',
              title: 'Resumo da Propriedade',
              subtitle: _propertySubtitle(scopedVisits),
              date: nowLabel,
              enabled: hasProperty,
              buildPayload: () => _buildPropertySummaryPayload(
                ref,
                scopedVisits,
                effectiveClientId,
              ),
            ),
            _GeneratedReportCard(
              leading: _relatoriosReportIconBadge(
                icon: SFIcons.calendar,
                accent: PremiumTokens.brandGreen,
              ),
              eyebrow: 'Gerado sob demanda',
              title: 'Histórico de Visitas',
              subtitle: '${scopedVisits.length} visita(s)',
              date: nowLabel,
              enabled: scopedVisits.isNotEmpty,
              buildPayload: () => _buildVisitHistoryPayload(
                ref,
                scopedVisits,
                effectiveClientId,
              ),
            ),
            if (combinedEvents.isEmpty)
              const _PremiumEmptyState(
                message: 'Nenhum relatório deste produtor para combinar.',
              )
            else
              _CombinedReportsComposer(
                clientId: effectiveClientId,
                dateFormat: dateFormat,
                events: combinedEvents,
              ),
          ],
        ],
        const SizedBox(height: kFabSafeArea),
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
