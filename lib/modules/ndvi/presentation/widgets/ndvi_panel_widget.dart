import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';

/// Painel NDVI expansível — integrado ao card de visita ativa.
///
/// Renderizado apenas quando [areaId] != null.
/// Exibe: dropdown de talhão · imagem NDVI 512px · navegação ‹ data › · fonte.
/// Não bloqueia o mapa — carregamento async com placeholders.
///
/// [initialAreaId] : areaId pré-selecionado da sessão ativa.
/// [talhaoOptions] : lista de (id, nome) para o dropdown de seleção.
class NdviPanelWidget extends ConsumerWidget {
  final String initialAreaId;

  /// Lista de (id, nome) dos talhões disponíveis na fazenda atual.
  final List<({String id, String nome})> talhaoOptions;

  const NdviPanelWidget({
    super.key,
    required this.initialAreaId,
    required this.talhaoOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAreaId =
        ref.watch(ndviSelectedAreaProvider(initialAreaId));
    final bboxAsync = ref.watch(ndviAreaBboxProvider(selectedAreaId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Divider separador ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            height: 0.5,
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),

        // ── Cabeçalho NDVI ───────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'NDVI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF3C3C43),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Dropdown de talhão ───────────────────────────────────────────
        if (talhaoOptions.length > 1)
          _TalhaoDropdown(
            selectedId: selectedAreaId,
            options: talhaoOptions,
            onChanged: (id) {
              ref.read(ndviSelectedAreaProvider(initialAreaId).notifier).state =
                  id;
              // Resetar índice de data ao trocar talhão
              ref.read(ndviDateIndexProvider(id).notifier).state = 0;
            },
          ),

        const SizedBox(height: 6),

        // ── Imagem NDVI ──────────────────────────────────────────────────
        bboxAsync.when(
          loading: () => const _NdviLoadingPlaceholder(),
          error: (_, __) => const _NdviErrorPlaceholder(),
          data: (bbox) {
            if (bbox == null) return const _NdviNoGeometryPlaceholder();
            return _NdviImageSection(
              areaId: selectedAreaId,
              bbox: bbox,
            );
          },
        ),
      ],
    );
  }
}

// ── Dropdown de seleção de talhão ─────────────────────────────────────────────

class _TalhaoDropdown extends StatelessWidget {
  final String selectedId;
  final List<({String id, String nome})> options;
  final ValueChanged<String> onChanged;

  const _TalhaoDropdown({
    required this.selectedId,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.any((o) => o.id == selectedId)
              ? selectedId
              : options.first.id,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF3C3C43),
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 14,
            color: PremiumTokens.brandGreen,
          ),
          items: options
              .map(
                (o) => DropdownMenuItem<String>(
                  value: o.id,
                  child: Text(o.nome, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Seção de imagem + navegação de datas ──────────────────────────────────────

class _NdviImageSection extends ConsumerWidget {
  final String areaId;
  final List<double> bbox;

  const _NdviImageSection({required this.areaId, required this.bbox});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateIndex = ref.watch(ndviDateIndexProvider(areaId));

    // Fetch inicial com date=null para obter a mais recente
    final initialParams = NdviFetchParams(areaId: areaId, bbox: bbox);
    final ndviAsync = ref.watch(ndviImageProvider(initialParams));

    return ndviAsync.when(
      loading: () => const _NdviLoadingPlaceholder(),
      error: (_, __) => const _NdviErrorPlaceholder(),
      data: (ndvi) {
        if (ndvi == null) return const _NdviEmptyPlaceholder();

        final dates = ndvi.availableDates;
        final clampedIndex =
            dates.isNotEmpty ? dateIndex.clamp(0, dates.length - 1) : 0;
        final currentDate =
            dates.isNotEmpty ? dates[clampedIndex] : ndvi.date;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagem ────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: _buildImage(ndvi),
              ),
            ),

            // ── Badge nuvem alta ──────────────────────────────────────
            if (ndvi.hasHighCloudCoverage)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Icon(Icons.cloud_outlined,
                        size: 10, color: Colors.orange.shade700),
                    const SizedBox(width: 3),
                    Text(
                      '${ndvi.cloudCoverage!.toStringAsFixed(0)}% nuvem',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // ── Navegação datas ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botão anterior
                GestureDetector(
                  onTap: clampedIndex > 0
                      ? () {
                          ref
                              .read(ndviDateIndexProvider(areaId).notifier)
                              .state = clampedIndex - 1;
                        }
                      : null,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: clampedIndex > 0
                        ? PremiumTokens.brandGreen
                        : Colors.grey.shade400,
                  ),
                ),

                // Data
                Text(
                  _formatDate(currentDate),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: Color(0xFF3C3C43),
                  ),
                ),

                // Botão próximo
                GestureDetector(
                  onTap: dates.isNotEmpty && clampedIndex < dates.length - 1
                      ? () {
                          ref
                              .read(ndviDateIndexProvider(areaId).notifier)
                              .state = clampedIndex + 1;
                        }
                      : null,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: dates.isNotEmpty && clampedIndex < dates.length - 1
                        ? PremiumTokens.brandGreen
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),

            // ── Fonte ─────────────────────────────────────────────────
            Center(
              child: Text(
                ndvi.source,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.3,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage(ndvi) {
    // Cache local disponível
    if (ndvi.imageCachePath != null) {
      final file = File(ndvi.imageCachePath as String);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildBase64OrPlaceholder(ndvi),
        );
      }
    }
    return _buildBase64OrPlaceholder(ndvi);
  }

  Widget _buildBase64OrPlaceholder(ndvi) {
    if (ndvi.imageBase64 != null &&
        (ndvi.imageBase64 as String).isNotEmpty) {
      try {
        final bytes = base64Decode(ndvi.imageBase64 as String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _NdviErrorPlaceholder(),
        );
      } catch (_) {
        return const _NdviErrorPlaceholder();
      }
    }
    return const _NdviErrorPlaceholder();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ── Placeholders ──────────────────────────────────────────────────────────────

class _NdviLoadingPlaceholder extends StatelessWidget {
  const _NdviLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: PremiumTokens.brandGreen.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _NdviErrorPlaceholder extends StatelessWidget {
  const _NdviErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            'Sem conexão',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _NdviEmptyPlaceholder extends StatelessWidget {
  const _NdviEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 18, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            'Sem imagens disponíveis',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _NdviNoGeometryPlaceholder extends StatelessWidget {
  const _NdviNoGeometryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 18, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            'Geometria não disponível',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
