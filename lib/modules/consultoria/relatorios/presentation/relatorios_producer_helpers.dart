part of 'relatorios_page.dart';

/// Dropdown de produtor — obrigatório quando há mais de um clientId.
class _RelatoriosProducerSelector extends ConsumerWidget {
  final List<String> producerIds;
  final Map<String, int> itemCounts;
  final String? selectedClientId;
  final ValueChanged<String> onSelected;

  const _RelatoriosProducerSelector({
    required this.producerIds,
    required this.itemCounts,
    required this.selectedClientId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelsAsync = ref.watch(
      _relatoriosProducerLabelsProvider(producerIds.join('|')),
    );

    return labelsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, __) => _producerDropdown(
        context,
        {for (final id in producerIds) id: id},
      ),
      data: (labels) => _producerDropdown(context, labels),
    );
  }

  Widget _producerDropdown(
    BuildContext context,
    Map<String, String> labels,
  ) {
    final effectiveValue =
        selectedClientId != null && producerIds.contains(selectedClientId)
        ? selectedClientId
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusSm),
        border: Border.all(color: const Color(0xFFD1D1D6)),
        boxShadow: PremiumTokens.premiumShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: effectiveValue,
          hint: Text(
            'Selecione um produtor',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.premiumTextSecondary,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.premiumTextSecondary,
          ),
          borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusSm),
          dropdownColor: context.premiumSurface,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.premiumTextPrimary,
          ),
          items: producerIds
              .map((id) {
                final label = labels[id] ?? id;
                final count = itemCounts[id] ?? 0;
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    '$label · $count',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              })
              .toList(),
          onChanged: (id) {
            if (id != null) onSelected(id);
          },
        ),
      ),
    );
  }
}

final _relatoriosProducerLabelsProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, producerKey) async {
      if (producerKey.isEmpty) return const {};
      final producerIds = producerKey.split('|');
      final lookup = ref.read(clientLookupProvider);
      final labels = <String, String>{};
      for (final id in producerIds) {
        labels[id] = await _resolveClienteNome(lookup, id);
      }
      return labels;
    });

Future<String> _resolveClienteNome(
  IClientLookup lookup,
  String clientId,
) async {
  try {
    final client = await lookup.findById(clientId);
    final name = client?.name.trim();
    if (name != null && name.isNotEmpty) return name;
  } catch (_) {
    // Lookup indisponível em testes sem override.
  }
  return clientId;
}

Future<String> _resolveClienteNomeForId(WidgetRef ref, String clientId) {
  return _resolveClienteNome(ref.read(clientLookupProvider), clientId);
}

List<RelatorioTecnico> _sortRelatoriosByPeriodStart(
  List<RelatorioTecnico> relatorios,
) {
  final sorted = [...relatorios]
    ..sort((a, b) => b.periodStart.compareTo(a.periodStart));
  return sorted;
}

List<Occurrence> _sortOccurrencesByCreatedAt(List<Occurrence> occurrences) {
  final sorted = [...occurrences]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted;
}

Map<String, int> _producerCountsFromIds(Iterable<String?> clientIds) {
  final counts = <String, int>{};
  for (final raw in clientIds) {
    final id = raw?.trim();
    if (id == null || id.isEmpty) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
}
