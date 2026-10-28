import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_refresh_provider.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';

/// Banner flutuante enquanto o NDVI do talhão selecionado carrega no mapa.
/// Persiste com o sheet recolhido/fechado ([mapNdviOverlayFieldIdProvider]).
class MapNdviLoadProgressOverlay extends ConsumerWidget {
  const MapNdviLoadProgressOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldId = ref.watch(mapNdviOverlayFieldIdProvider);
    if (fieldId == null || fieldId.isEmpty) {
      return const SizedBox.shrink();
    }

    final summaryAsync = ref.watch(mapNdviOverlaySummaryProvider);
    final summary = summaryAsync.asData?.value;
    if (mapNdviSummaryCoversField(summary)) {
      return const SizedBox.shrink();
    }

    final fieldName = _fieldName(ref, fieldId);
    final isLoading = summaryAsync.isLoading || summaryAsync.isRefreshing;
    final hasError = summaryAsync.hasError;
    final padding = MediaQuery.paddingOf(context);
    final bottomInset =
        padding.bottom + kFabSafeArea + 12 + kMapActionColumnButtonSize;

    return Positioned(
      left: 16,
      right: 16 + kMapActionColumnRightInset + kMapActionColumnButtonSize,
      bottom: bottomInset,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fieldName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isLoading
                              ? 'Baixando mapa NDVI…'
                              : hasError
                              ? 'Não foi possível carregar o NDVI. Tente novamente.'
                              : 'NDVI ainda não disponível para este talhão.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                          ),
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: const LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: Color(0xFF3A3A3C),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0A84FF),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 2),
                      child: CupertinoActivityIndicator(radius: 11),
                    )
                  else if (hasError || summary == null)
                    IconButton(
                      tooltip: 'Tentar novamente',
                      onPressed: () async {
                        await ref
                            .read(ndviFieldRefreshProvider)
                            .clearCacheAndReload(fieldId);
                        ref.invalidate(mapNdviOverlaySummaryProvider);
                      },
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF0A84FF),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Desativar NDVI no mapa',
                    onPressed: () {
                      ref.read(mapNdviOverlayFieldIdProvider.notifier).state =
                          null;
                      ref
                          .read(mapNdviMonochromeEnabledProvider.notifier)
                          .state = false;
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fieldName(WidgetRef ref, String fieldId) {
    final features = ref.read(drawingControllerProvider).features;
    for (final feature in features) {
      if (feature.id == fieldId) {
        final name = feature.properties.nome.trim();
        if (name.isNotEmpty) return name;
      }
    }
    return 'Talhão';
  }
}
