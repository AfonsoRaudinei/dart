import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';
import 'package:soloforte_app/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

class FieldDetailScreen extends ConsumerWidget {
  final String farmId;
  final String fieldId; // Talhao

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
            // Header
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
                    _buildNdviSection(context, ref),
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

  Widget _buildNdviSection(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(ndviLatestProvider(fieldId));

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
            data: (image) => image == null
                ? _buildNdviEmpty(context)
                : _buildNdviPreviewCard(context, image),
          ),
        ],
      ),
    );
  }

  Widget _buildNdviEmpty(BuildContext context) {
    return Text(
      'NDVI não disponível para este talhão',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildNdviPreviewCard(BuildContext context, NdviImage image) {
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
                  'Última imagem: ${_formatDate(image.imageDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  ndviSourceLabel(image.source),
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
                  'NDVI médio: ${image.ndviMean.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  'Mín: ${image.ndviMin.toStringAsFixed(2)}  '
                  'Máx: ${image.ndviMax.toStringAsFixed(2)}',
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
                onPressed: () => showSoloForteSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  showDragHandle: false,
                  useSafeArea: false,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (_) => NdviTalhaoSheet(
                    fieldId: fieldId,
                    fieldName: 'Talhão $fieldId',
                  ),
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
