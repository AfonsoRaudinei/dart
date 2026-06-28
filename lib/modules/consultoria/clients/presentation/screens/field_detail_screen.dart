import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_presenter_provider.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';

/// Detalhe de talhão — NDVI via contratos neutros (ADR-045).
class FieldDetailScreen extends ConsumerWidget {
  final String farmId;
  final String fieldId;

  const FieldDetailScreen({
    super.key,
    required this.farmId,
    required this.fieldId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Talhão',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildInfoSection(context),
                    const SizedBox(height: 24),
                    _NdviPreviewSection(fieldId: fieldId),
                    const SizedBox(height: kFabSafeArea),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Talhão', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('ID: $fieldId', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

final _fieldNdviLatestProvider = FutureProvider.autoDispose
    .family<NdviLatestSummary?, String>((ref, fieldId) {
      return ref.watch(ndviLatestLookupProvider).getLatest(fieldId);
    });

class _NdviPreviewSection extends ConsumerWidget {
  const _NdviPreviewSection({required this.fieldId});

  final String fieldId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(_fieldNdviLatestProvider(fieldId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NDVI', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          latestAsync.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) => summary == null
                ? _buildEmpty(context)
                : _buildPreviewCard(context, ref, summary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Text(
      'NDVI não disponível para este talhão',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    WidgetRef ref,
    NdviLatestSummary summary,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.satellite_alt_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Última imagem: ${_formatDate(summary.imageDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  summary.sourceLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'NDVI médio: ${summary.ndviMean.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  'Mín: ${summary.ndviMin.toStringAsFixed(2)}  '
                  'Máx: ${summary.ndviMax.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref.read(ndviFieldPresenterProvider).showTalhaoSheet(
                  context,
                  fieldId: fieldId,
                  fieldName: 'Talhão $fieldId',
                ),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Ver histórico'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
