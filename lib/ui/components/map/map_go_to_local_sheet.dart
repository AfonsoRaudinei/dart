import 'package:flutter/material.dart';

import '../../../core/constants/layout_constants.dart';
import '../../../core/ui/sheets/sheet_tokens.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import '../../theme/premium/design_tokens.dart';

/// Escolha entre ir para município ou coordenada (chrome do mapa).
Future<void> showMapGoToLocalSheet(
  BuildContext context, {
  required Future<void> Function() onMunicipalitySearch,
  required Future<void> Function() onCoordinateSearch,
}) {
  return showSoloForteSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    maxHeightFraction: 0.42,
    builder: (_) => MapGoToLocalSheet(
      onMunicipalitySearch: onMunicipalitySearch,
      onCoordinateSearch: onCoordinateSearch,
    ),
  );
}

class MapGoToLocalSheet extends StatelessWidget {
  static const _accent = PremiumTokens.brandGreenDark;

  final Future<void> Function() onMunicipalitySearch;
  final Future<void> Function() onCoordinateSearch;

  const MapGoToLocalSheet({
    super.key,
    required this.onMunicipalitySearch,
    required this.onCoordinateSearch,
  });

  @override
  Widget build(BuildContext context) {
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
      child: SingleChildScrollView(
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
                    'Ir para local',
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
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: false).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isIos ? SoloForteSheetSkinIos.ghostText : _accent,
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
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Icon(
              Icons.location_city_outlined,
              color: isIos
                  ? SoloForteSheetSkinIos.iconStroke
                  : Colors.white70,
            ),
            title: Text(
              'Ir para município',
              style: TextStyle(
                color: isIos
                    ? SoloForteSheetSkinIos.titleColor
                    : Colors.white,
              ),
            ),
            onTap: () async {
              Navigator.of(context, rootNavigator: false).pop();
              await onMunicipalitySearch();
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Icon(
              Icons.search_rounded,
              color: isIos
                  ? SoloForteSheetSkinIos.iconStroke
                  : Colors.white70,
            ),
            title: Text(
              'Ir para coordenada',
              style: TextStyle(
                color: isIos
                    ? SoloForteSheetSkinIos.titleColor
                    : Colors.white,
              ),
            ),
            onTap: () async {
              Navigator.of(context, rootNavigator: false).pop();
              await onCoordinateSearch();
            },
          ),
          const SizedBox(height: kFabSafeArea),
          ],
        ),
      ),
    );
  }
}
