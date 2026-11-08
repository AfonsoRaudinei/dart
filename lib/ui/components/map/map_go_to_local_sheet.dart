import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

import '../../../core/constants/layout_constants.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';

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
  final Future<void> Function() onMunicipalitySearch;
  final Future<void> Function() onCoordinateSearch;

  const MapGoToLocalSheet({
    super.key,
    required this.onMunicipalitySearch,
    required this.onCoordinateSearch,
  });

  @override
  Widget build(BuildContext context) {
        final v = SoloForteSheetVisuals.of(context);
    final bg = v.sheetBackground;
    final radius = v.sheetRadius;

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
                      fontSize: v.titleFontSize,
                      fontWeight: v.titleWeight,
                      color: v.titleColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: false).pop(),
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
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Icon(
              Icons.location_city_outlined,
              color: v.isIos ? v.iconStroke : v.subtitleColor,
            ),
            title: Text(
              'Ir para município',
              style: TextStyle(
                color: v.titleColor,
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
              color: v.isIos ? v.iconStroke : v.subtitleColor,
            ),
            title: Text(
              'Ir para coordenada',
              style: TextStyle(
                color: v.titleColor,
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
