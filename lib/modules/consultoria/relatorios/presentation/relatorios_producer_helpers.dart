part of 'relatorios_page.dart';

/// Chips de produtor — obrigatório quando há mais de um clientId.
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
      error: (_, __) => Wrap(
        spacing: 8,
        runSpacing: 6,
        children: producerIds
            .map((id) => _producerChip(context, id, id, itemCounts[id] ?? 0))
            .toList(),
      ),
      data: (labels) => Wrap(
        spacing: 8,
        runSpacing: 6,
        children: producerIds
            .map(
              (id) => _producerChip(
                context,
                id,
                labels[id] ?? id,
                itemCounts[id] ?? 0,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _producerChip(
    BuildContext context,
    String clientId,
    String label,
    int count,
  ) {
    final isSelected = selectedClientId == clientId;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(clientId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? PremiumTokens.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? PremiumTokens.brandGreen
                : const Color(0xFFD1D1D6),
          ),
        ),
        child: Text(
          '$label · $count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.premiumTextPrimary,
          ),
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
