import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../design/sf_icons.dart';
import '../../image/vegetal_filter.dart';
import '../../ui/sheets/sheet_tokens.dart';
import '../../ui/sheets/soloforte_sheet.dart';
import '../../utils/app_logger.dart';

enum _PhotoPickerOrigin { camera, gallery, vegetal }

/// Ponto de entrada único do picker de foto compartilhado.
///
/// Fecha o sheet, resolve o arquivo (câmera, galeria ou inversão vegetal)
/// e chama [onPhotoSelected] com o path local. Cancelar o sheet não chama
/// o callback.
Future<void> showSoloFortePhotoPicker({
  required BuildContext context,
  required String label,
  required Future<void> Function(String path) onPhotoSelected,
}) async {
  final origin = await showSoloForteSheet<_PhotoPickerOrigin>(
    context: context,
    backgroundColor: null,
    showDragHandle: false,
    builder: (sheetContext) => SoloFortePhotoPickerSheet(label: label),
  );
  if (origin == null || !context.mounted) return;

  final path = await _resolvePhotoPath(origin);
  if (path == null || !context.mounted) return;

  await onPhotoSelected(path);
}

Future<String?> _resolvePhotoPath(_PhotoPickerOrigin origin) async {
  try {
    switch (origin) {
      case _PhotoPickerOrigin.camera:
        return _pickRaw(ImageSource.camera);
      case _PhotoPickerOrigin.gallery:
        return _pickRaw(ImageSource.gallery);
      case _PhotoPickerOrigin.vegetal:
        return _pickVegetalInversion();
    }
  } catch (e, st) {
    AppLogger.error(
      'SoloFortePhotoPicker failed for $origin',
      error: e,
      stackTrace: st,
    );
    return null;
  }
}

Future<String?> _pickRaw(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 85,
  );
  return picked?.path;
}

Future<String?> _pickVegetalInversion() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 85,
  );
  if (picked == null) return null;

  final sourceBytes = await File(picked.path).readAsBytes();
  final filtered = await compute(encodeVegetalFilteredJpeg, sourceBytes);
  if (filtered == null) {
    AppLogger.warning(
      'Inversão vegetal: decode/encode retornou null',
      tag: 'PhotoPicker',
    );
    return null;
  }

  final dir = await getTemporaryDirectory();
  final out = File(
    '${dir.path}/vegetal_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await out.writeAsBytes(filtered, flush: true);
  return out.path;
}

/// Bottom sheet com as três origens de foto. Não instanciar direto —
/// usar [showSoloFortePhotoPicker].
class SoloFortePhotoPickerSheet extends StatelessWidget {
  final String label;

  const SoloFortePhotoPickerSheet({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final cardBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : Theme.of(context).scaffoldBackgroundColor;
    final titleColor = isIos ? SoloForteSheetSkinIos.titleColor : null;
    final subColor = isIos ? SoloForteSheetSkinIos.subtitleColor : null;
    final radius = isIos ? SoloForteSheetSkinIos.sheetRadius : 20.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: isIos
            ? Border.all(color: SoloForteSheetSkinIos.cardBorder)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isIos ? SoloForteSheetSkinIos.handleSize.width : 36,
            height: isIos ? SoloForteSheetSkinIos.handleSize.height : 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isIos
                  ? SoloForteSheetSkinIos.handleColor
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: titleColor,
              ),
            ),
          ),
          _PhotoPickerTile(
            icon: Icons.camera_alt,
            iconBg: isIos
                ? SoloForteSheetSkinIos.iconBackground
                : Colors.blue.shade50,
            iconFg: isIos
                ? SoloForteSheetSkinIos.iconStroke
                : Colors.blue.shade600,
            title: 'Câmera',
            subtitle: 'Tirar nova foto',
            titleColor: titleColor,
            subtitleColor: subColor,
            onTap: () => Navigator.of(context).pop(_PhotoPickerOrigin.camera),
          ),
          _PhotoPickerTile(
            icon: Icons.photo_library,
            iconBg: isIos
                ? SoloForteSheetSkinIos.iconBackground
                : Colors.purple.shade50,
            iconFg: isIos
                ? SoloForteSheetSkinIos.iconStroke
                : Colors.purple.shade600,
            title: 'Galeria',
            subtitle: 'Escolher da biblioteca de fotos',
            titleColor: titleColor,
            subtitleColor: subColor,
            onTap: () => Navigator.of(context).pop(_PhotoPickerOrigin.gallery),
          ),
          _PhotoPickerTile(
            icon: SFIcons.leaf,
            iconBg: isIos
                ? SoloForteSheetSkinIos.iconBackground
                : Colors.green.shade50,
            iconFg: isIos
                ? SoloForteSheetSkinIos.iconStroke
                : Colors.green.shade700,
            title: 'Inversão vegetal',
            subtitle: 'Câmera com filtro de inversão',
            titleColor: titleColor,
            subtitleColor: subColor,
            onTap: () => Navigator.of(context).pop(_PhotoPickerOrigin.vegetal),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PhotoPickerTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final VoidCallback onTap;

  const _PhotoPickerTile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconFg),
      ),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: Text(subtitle, style: TextStyle(color: subtitleColor)),
      onTap: onTap,
    );
  }
}
