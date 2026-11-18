import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soloforte_app/core/geo/kml_exporter.dart';
import 'package:soloforte_app/core/ui/keyboard_dismiss.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/utils/share_position.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import 'providers/field_providers.dart';

class FarmGeometryExportItem {
  const FarmGeometryExportItem({
    required this.name,
    required this.areaHa,
    this.geojson,
  });

  final String name;
  final double? areaHa;
  final String? geojson;
}

enum _FarmGeometryExportFormat { kml, kmz }

/// Ícone/botão quando há GeoJSON ou contorno com pelo menos 3 vértices.
bool canOfferFieldGeometryExport({String? geojson, int vertexCount = 0}) {
  final raw = geojson?.trim();
  if (raw != null && raw.isNotEmpty) return true;
  return vertexCount >= 3;
}

/// Abaixo de “Baixar mapa”. Compartilha os polígonos da fazenda.
class FarmGeometryExportButton extends StatelessWidget {
  const FarmGeometryExportButton({
    super.key,
    required this.documentName,
    required this.fields,
  });

  final String documentName;
  final List<FarmLinkedFieldSummary>? fields;

  @override
  Widget build(BuildContext context) {
    final list = fields ?? const <FarmLinkedFieldSummary>[];
    final enabled = list.any(
      (field) => canOfferFieldGeometryExport(
        geojson: field.geojson,
        vertexCount: field.vertices.length,
      ),
    );
    final color = enabled ? PremiumTokens.brandGreen : Colors.grey;

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: enabled
            ? () => exportFieldGeometries(
                context: context,
                documentName: documentName,
                items: [
                  for (final field in list)
                    FarmGeometryExportItem(
                      name: field.name,
                      areaHa: field.areaHa,
                      geojson: field.geojson,
                    ),
                ],
              )
            : null,
        icon: Icon(Icons.ios_share_outlined, color: color),
        label: Text(
          'Exportar KML',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

Future<void> exportFieldGeometries({
  required BuildContext context,
  required String documentName,
  required List<FarmGeometryExportItem> items,
}) async {
  final placemarks = <KmlPlacemark>[];
  for (final item in items) {
    final geojson = item.geojson;
    if (geojson == null || geojson.trim().isEmpty) continue;
    if (!kmlGeometryHasValidPolygon(geojson)) continue;
    placemarks.add(
      KmlPlacemark(name: item.name, areaHa: item.areaHa, geometry: geojson),
    );
  }
  if (placemarks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nenhum talhão desenhado para exportar.')),
    );
    return;
  }

  final format = await _selectExportFormat(context);
  if (format == null || !context.mounted) return;

  try {
    final base = _fileBaseName(documentName);
    final isKmz = format == _FarmGeometryExportFormat.kmz;
    final fileName = isKmz ? '$base.kmz' : '$base.kml';
    final mime = isKmz
        ? 'application/vnd.google-earth.kmz'
        : 'application/vnd.google-earth.kml+xml';
    final bytes = isKmz
        ? buildKmzBytes(documentName: documentName, placemarks: placemarks)
        : utf8.encode(
            buildKmlDocument(
              documentName: documentName,
              placemarks: placemarks,
            ),
          );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    if (!context.mounted) return;
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mime, name: fileName)],
      subject: fileName,
      sharePositionOrigin: resolveSharePositionOrigin(context),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userFacingError(error, action: 'Erro ao exportar')),
      ),
    );
  }
}

Future<_FarmGeometryExportFormat?> _selectExportFormat(BuildContext context) {
  return showSoloForteSheet<_FarmGeometryExportFormat>(
    context: context,
    builder: (ctx) {
      final visuals = SoloForteSheetVisuals.of(ctx);
      final isIos = visuals.isIos;
      final titleColor = isIos ? visuals.titleColor : null;
      final subtitleColor = isIos ? visuals.subtitleColor : null;
      final iconColor = visuals.accent;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Formato de exportação',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.public_outlined, color: iconColor),
              title: Text('KML', style: TextStyle(color: titleColor)),
              subtitle: Text(
                'Google Earth e GPS',
                style: TextStyle(color: subtitleColor),
              ),
              onTap: () => _popLocalDialog(ctx, _FarmGeometryExportFormat.kml),
            ),
            ListTile(
              leading: Icon(Icons.folder_zip_outlined, color: iconColor),
              title: Text('KMZ', style: TextStyle(color: titleColor)),
              subtitle: Text(
                'KML compactado',
                style: TextStyle(color: subtitleColor),
              ),
              onTap: () => _popLocalDialog(ctx, _FarmGeometryExportFormat.kmz),
            ),
          ],
        ),
      );
    },
  );
}

void _popLocalDialog(BuildContext context, [Object? result]) {
  SoloforteKeyboardDismiss.dismiss();
  final navigator = Navigator.of(context, rootNavigator: false);
  if (result != null) {
    navigator.pop(result);
  } else {
    navigator.pop();
  }
}

String _fileBaseName(String documentName) {
  final cleaned = documentName
      .replaceAll(RegExp(r'[^\p{L}\p{N} _-]', unicode: true), '')
      .trim();
  if (cleaned.isEmpty) return 'soloforte_talhoes';
  return cleaned;
}
