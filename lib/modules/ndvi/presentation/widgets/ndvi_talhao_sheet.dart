import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_date_nav_provider.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_display_mode_provider.dart';

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
    ref.watch(ndviEnsureCurrentDateProvider(fieldId));
    final ndviAsync = ref.watch(ndviImagesProvider(fieldId));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
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

          Expanded(
            child: Padding(
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
                  final modeKey =
                      '$fieldId:${current.id}:${current.imageDate.toIso8601String()}';
                  final displayMode = ref.watch(
                    ndviDisplayModeProvider(modeKey),
                  );

                  return SingleChildScrollView(
                    child: Column(
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(
                              icon: Icons.calendar_today_outlined,
                              label: _formatDate(current.imageDate),
                            ),
                            _InfoPill(
                              icon: Icons.cloud_outlined,
                              label: ndviSourceLabel(current.source),
                            ),
                            _InfoPill(
                              icon: Icons.storage_outlined,
                              label: _imageStatusLabel(current),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (images.length > 1) ...[
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, chipIndex) {
                                final image = images[chipIndex];
                                return ChoiceChip(
                                  label: Text(_shortDate(image.imageDate)),
                                  selected: chipIndex == safeIndex,
                                  onSelected: (_) {
                                    ref
                                            .read(
                                              ndviDateIndexProvider(
                                                fieldId,
                                              ).notifier,
                                            )
                                            .state =
                                        chipIndex;
                                  },
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemCount: images.length,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (ndviPreviewDisclaimer(current.source) != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              ndviPreviewDisclaimer(current.source)!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (ndviSupportsGreenMask(current.source)) ...[
                          SegmentedButton<NdviDisplayMode>(
                            segments: const [
                              ButtonSegment(
                                value: NdviDisplayMode.color,
                                icon: Icon(Icons.palette_outlined),
                                label: Text('NDVI'),
                              ),
                              ButtonSegment(
                                value: NdviDisplayMode.greenMask,
                                icon: Icon(Icons.filter_b_and_w_outlined),
                                label: Text('Máscara verde'),
                              ),
                            ],
                            selected: {displayMode},
                            onSelectionChanged: (selection) {
                              ref
                                  .read(ndviDisplayModeProvider(modeKey).notifier)
                                  .state = selection
                                  .first;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Imagem
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _buildImage(ref, current, displayMode),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: _ModeBadge(displayMode: displayMode),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        _NdviLegend(displayMode: displayMode),

                        const SizedBox(height: 16),

                        // Navegação
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: safeIndex < images.length - 1
                                  ? () =>
                                        ref
                                                .read(
                                                  ndviDateIndexProvider(
                                                    fieldId,
                                                  ).notifier,
                                                )
                                                .state =
                                            safeIndex + 1
                                  : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '${safeIndex + 1} de ${images.length} imagens',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: safeIndex > 0
                                  ? () =>
                                        ref
                                                .read(
                                                  ndviDateIndexProvider(
                                                    fieldId,
                                                  ).notifier,
                                                )
                                                .state =
                                            safeIndex - 1
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
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(
    WidgetRef ref,
    NdviImage current,
    NdviDisplayMode displayMode,
  ) {
    if (displayMode == NdviDisplayMode.greenMask &&
        ndviSupportsGreenMask(current.source)) {
      return _buildGreenMaskImage(ref, current);
    }

    if (current.localPath != null) {
      final file = File(current.localPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    if (current.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: current.imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const _ImageUnavailable(),
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
      );
    }

    return const _ImageUnavailable();
  }

  Widget _buildGreenMaskImage(WidgetRef ref, NdviImage current) {
    final localPath = current.localPath;
    if (localPath == null || localPath.isEmpty) {
      return const _MaskUnavailable();
    }

    final maskAsync = ref.watch(ndviGreenMaskBytesProvider(localPath));
    return maskAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _MaskUnavailable(),
      data: (bytes) => bytes == null
          ? const _MaskUnavailable()
          : Image.memory(bytes, fit: BoxFit.cover),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _imageStatusLabel(NdviImage image) {
    if (image.localPath != null && image.localPath!.isNotEmpty) {
      return 'Cache local';
    }
    if (image.imageUrl != null && image.imageUrl!.isNotEmpty) {
      return 'Online';
    }
    return 'Indisponivel';
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

class _MaskUnavailable extends StatelessWidget {
  const _MaskUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.filter_b_and_w_outlined, color: Colors.white, size: 48),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.satellite_alt_outlined, color: Colors.white, size: 48),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final NdviDisplayMode displayMode;

  const _ModeBadge({required this.displayMode});

  @override
  Widget build(BuildContext context) {
    final isMask = displayMode == NdviDisplayMode.greenMask;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isMask ? 'Modo: Mascara verde' : 'Modo: NDVI',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _NdviLegend extends StatelessWidget {
  final NdviDisplayMode displayMode;

  const _NdviLegend({required this.displayMode});

  @override
  Widget build(BuildContext context) {
    final items = displayMode == NdviDisplayMode.greenMask
        ? const [
            _LegendItem(color: Colors.white, label: 'Vegetacao'),
            _LegendItem(color: Colors.black, label: 'Nao vegetacao'),
          ]
        : const [
            _LegendItem(color: Color(0xFFE53935), label: 'Baixo'),
            _LegendItem(color: Color(0xFFFDD835), label: 'Medio'),
            _LegendItem(color: Color(0xFF43A047), label: 'Alto'),
          ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items.map((item) => _LegendChip(item: item)).toList(),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final _LegendItem item;

  const _LegendChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(width: 6),
        Text(item.label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});
}
