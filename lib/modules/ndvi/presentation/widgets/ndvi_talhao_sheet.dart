import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_date_nav_provider.dart';

class NdviTalhaoSheet extends ConsumerWidget {
  final String fieldId;
  final String fieldName;
  final double? areaHa;

  const NdviTalhaoSheet({
    super.key,
    required this.fieldId,
    required this.fieldName,
    this.areaHa,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ndviAsync = ref.watch(ndviImagesProvider(fieldId));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ndviAsync.when(
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorState(
                onRetry: () => ref.invalidate(ndviImagesProvider(fieldId)),
              ),
              data: (images) {
                if (images.isEmpty) return const _EmptyState();

                final index = ref.watch(ndviDateIndexProvider(fieldId));
                final safeIndex = index.clamp(0, images.length - 1);
                final current = images[safeIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          fieldName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (areaHa != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•  ${areaHa!.toStringAsFixed(1)} ha',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fonte: ${current.source}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Data: ${_formatDate(current.imageDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Imagem
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: _buildImage(current),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Navegação
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: safeIndex < images.length - 1
                              ? () => ref
                                  .read(ndviDateIndexProvider(fieldId).notifier)
                                  .state = safeIndex + 1
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${safeIndex + 1} de ${images.length} imagens',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          onPressed: safeIndex > 0
                              ? () => ref
                                  .read(ndviDateIndexProvider(fieldId).notifier)
                                  .state = safeIndex - 1
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Dados NDVI
                    Text(
                      'NDVI médio: ${current.ndviMean.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mín: ${current.ndviMin.toStringAsFixed(2)}   Máx: ${current.ndviMax.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: kFabSafeArea),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(NdviImage current) {
    if (current.localPath != null) {
      final file = File(current.localPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    if (current.imageUrl != null) {
      return Image.network(
        current.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _FallbackGradient(),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    return const _FallbackGradient();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Erro ao carregar imagens NDVI'),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'Nenhuma imagem disponível para este talhão',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class _FallbackGradient extends StatelessWidget {
  const _FallbackGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Colors.red,
            Colors.yellow,
            Colors.green,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.satellite_alt_outlined, color: Colors.white, size: 48),
      ),
    );
  }
}
