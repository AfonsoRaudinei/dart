import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/layout_constants.dart';
import '../../../core/ui/sheets/sheet_tokens.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import 'widgets/map_offline_widgets.dart';

class LayersSheet extends ConsumerWidget {
  final VoidCallback? onClose;
  final Future<void> Function()? onDownloadOfflineArea;

  const LayersSheet({
    super.key,
    this.onClose,
    this.onDownloadOfflineArea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = SoloForteSheetVisuals.of(context);
    // Host do mapa usa preserveMaterialDefaults (Scope forçado em light);
    // re-propaga a variante real do tema para o conteúdo.
    return SoloForteSheetSkinScope(
      variant: soloForteSheetVariantFromThemeId(
        Theme.of(context).extension<SoloForteThemeExtension>()?.themeId,
      ),
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final bg = v.sheetBackground;
    final radius = v.sheetRadius;

    return Material(
      color: bg,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Camadas',
                    style: TextStyle(
                      fontSize: v.titleFontSize,
                      fontWeight: v.titleWeight,
                      color: v.titleColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      onClose ??
                      () => Navigator.of(context, rootNavigator: false).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: v.ghostText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: v.dividerColor,
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              children: [
                MapOfflineStatusCard(
                  onDownloadOfflineArea: onDownloadOfflineArea,
                ),
                const SizedBox(height: kFabSafeArea),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
