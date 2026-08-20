import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/offline_tile_cache_service.dart';
import '../../../core/ui/sheets/sheet_tokens.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../core/ui/sheets/widgets/sheet_input_field.dart';

class MapOfflineDownloadParams {
  final int minZoom;
  final int maxZoom;

  const MapOfflineDownloadParams({
    required this.minZoom,
    required this.maxZoom,
  });
}

/// Sheet de configuração do download offline da área visível.
Future<MapOfflineDownloadParams?> showMapOfflineDownloadSheet(
  BuildContext context,
) {
  return showSoloForteSheet<MapOfflineDownloadParams>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    maxHeightFraction: 0.62,
    builder: (ctx) => const MapOfflineDownloadSheet(),
  );
}

/// Sheet de progresso do download (não dismissível).
Future<void> showMapOfflineDownloadProgressSheet(
  BuildContext context, {
  required ValueNotifier<OfflinePrefetchProgress> progress,
  required VoidCallback onCancel,
}) {
  return showSoloForteSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: false,
    maxHeightFraction: 0.38,
    builder: (ctx) => MapOfflineDownloadProgressSheet(
      progress: progress,
      onCancel: onCancel,
    ),
  );
}

class MapOfflineDownloadSheet extends StatefulWidget {
  const MapOfflineDownloadSheet({super.key});

  @override
  State<MapOfflineDownloadSheet> createState() =>
      _MapOfflineDownloadSheetState();
}

class _MapOfflineDownloadSheetState extends State<MapOfflineDownloadSheet> {
  final _minZoomController = TextEditingController(text: '12');
  final _maxZoomController = TextEditingController(text: '18');

  @override
  void dispose() {
    _minZoomController.dispose();
    _maxZoomController.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(
      MapOfflineDownloadParams(
        minZoom: int.tryParse(_minZoomController.text) ?? 12,
        maxZoom: int.tryParse(_maxZoomController.text) ?? 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.titleColor;
    final bodyColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final ctaBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : SoloForteSheetTokens.chipBorderActive;
    final ctaFg = isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final ghostBorder = isIos
        ? SoloForteSheetSkinIos.ghostBorder
        : SoloForteSheetTokens.divider;
    final ghostText = isIos
        ? SoloForteSheetSkinIos.ghostText
        : SoloForteSheetTokens.chipTextInactive;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Baixar área offline',
              style: TextStyle(
                color: titleColor,
                fontSize: SoloForteSheetTokens.titleFontSize,
                fontWeight: SoloForteSheetTokens.titleWeight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Será usada a área visível atual do mapa (bounding box).',
              style: TextStyle(color: bodyColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SheetInputField(
              controller: _minZoomController,
              keyboardType: TextInputType.number,
              labelText: 'Zoom mínimo',
            ),
            const SizedBox(height: 12),
            SheetInputField(
              controller: _maxZoomController,
              keyboardType: TextInputType.number,
              labelText: 'Zoom máximo',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ghostText,
                      side: BorderSide(color: ghostBorder),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isIos
                              ? SoloForteSheetSkinIos.ghostRadius
                              : SoloForteSheetTokens.chipRadius,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ctaBg,
                      foregroundColor: ctaFg,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isIos
                              ? SoloForteSheetSkinIos.ctaRadius
                              : SoloForteSheetTokens.chipRadius,
                        ),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text('Baixar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MapOfflineDownloadProgressSheet extends StatelessWidget {
  final ValueNotifier<OfflinePrefetchProgress> progress;
  final VoidCallback onCancel;

  const MapOfflineDownloadProgressSheet({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.titleColor;
    final bodyColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final ghostText = isIos
        ? SoloForteSheetSkinIos.ghostText
        : SoloForteSheetTokens.chipTextInactive;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
        child: ValueListenableBuilder<OfflinePrefetchProgress>(
          valueListenable: progress,
          builder: (_, value, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Baixando área offline',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: SoloForteSheetTokens.titleFontSize,
                    fontWeight: SoloForteSheetTokens.titleWeight,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: value.fraction),
                const SizedBox(height: 12),
                Text(
                  '${value.processed} de ${value.total} tiles',
                  style: TextStyle(color: bodyColor, fontSize: 14),
                ),
                if (value.failed > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Falhas: ${value.failed}',
                    style: TextStyle(color: bodyColor, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: ghostText,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
