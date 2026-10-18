import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/layout_constants.dart';
import '../../../core/ui/sheets/sheet_tokens.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import 'widgets/map_offline_widgets.dart';
import '../../theme/premium/design_tokens.dart';

class LayersSheet extends ConsumerWidget {
  static const _accent = PremiumTokens.brandGreenDark;

  final VoidCallback? onClose;
  final Future<void> Function()? onDownloadOfflineArea;

  const LayersSheet({
    super.key,
    this.onClose,
    this.onDownloadOfflineArea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIos = soloForteSheetIsIos(context);
    final bg = isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
    final radius = isIos
        ? SoloForteSheetSkinIos.sheetRadius
        : SoloForteSheetTokens.borderRadius;

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
                      fontSize: isIos ? 16 : SoloForteSheetTokens.titleFontSize,
                      fontWeight: isIos
                          ? FontWeight.w700
                          : SoloForteSheetTokens.titleWeight,
                      color: isIos
                          ? SoloForteSheetSkinIos.titleColor
                          : SoloForteSheetTokens.titleColor,
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
                      color: isIos
                          ? SoloForteSheetSkinIos.ghostText
                          : _accent,
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
            color: isIos
                ? SoloForteSheetSkinIos.rowDivider
                : SoloForteSheetTokens.divider,
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
