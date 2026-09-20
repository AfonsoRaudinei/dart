import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../core/utils/map_location_export.dart';
import '../../../../core/utils/share_position.dart';
import '../../../theme/premium/design_tokens.dart';
import '../../premium/premium_glass_panel.dart';

/// Sheet de exportação de coordenadas para apps de mapa/rotas.
class LocationExportBottomSheet extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String label;

  const LocationExportBottomSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    this.label = 'Área Visitada',
  });

  static Future<void> show({
    required BuildContext context,
    required double latitude,
    required double longitude,
    String label = 'Área Visitada',
  }) {
    if (!MapLocationExport.isValidCoordinate(latitude, longitude)) {
      return Future.value();
    }
    return showSoloForteSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      builder: (_) => LocationExportBottomSheet(
        latitude: latitude,
        longitude: longitude,
        label: label,
      ),
    );
  }

  void _dismiss(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o app de mapas.'),
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyCoordinates(BuildContext context) async {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    final text = MapLocationExport.formatDecimalLatLng(latitude, longitude);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordenadas copiadas')),
    );
  }

  Future<void> _shareLocation(BuildContext context) async {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    final text = MapLocationExport.shareText(
      latitude,
      longitude,
      label: label,
    );
    await Share.share(
      text,
      sharePositionOrigin: resolveSharePositionOrigin(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isIos = soloForteSheetIsIos(context);
    final coordsPreview = MapLocationExport.formatDecimalLatLng(
      latitude,
      longitude,
    );

    if (isIos) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: SoloForteSheetSkinIos.cardBackground,
                  borderRadius:
                      BorderRadius.circular(SoloForteSheetSkinIos.cardRadius),
                  border: Border.all(color: SoloForteSheetSkinIos.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exportar localização',
                            style: TextStyle(
                              color: SoloForteSheetSkinIos.titleColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coordsPreview,
                            style: const TextStyle(
                              color: SoloForteSheetSkinIos.subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ActionRow(
                      icon: SFIcons.map,
                      title: 'Google Maps',
                      color: SoloForteSheetSkinIos.iconStroke,
                      isIos: true,
                      onTap: () => _openExternalUrl(
                        context,
                        MapLocationExport.googleMapsUrl(latitude, longitude),
                      ),
                    ),
                    _ActionRow(
                      icon: SFIcons.pinFill,
                      title: 'Apple Maps',
                      color: SoloForteSheetSkinIos.iconStroke,
                      isIos: true,
                      onTap: () => _openExternalUrl(
                        context,
                        MapLocationExport.appleMapsUrl(latitude, longitude),
                      ),
                    ),
                    _ActionRow(
                      icon: SFIcons.assignment,
                      title: 'Copiar coordenadas',
                      color: SoloForteSheetSkinIos.iconStroke,
                      isIos: true,
                      onTap: () => _copyCoordinates(context),
                    ),
                    _ActionRow(
                      icon: Icons.ios_share_outlined,
                      title: 'Compartilhar',
                      color: SoloForteSheetSkinIos.iconStroke,
                      isIos: true,
                      showDivider: false,
                      onTap: () => _shareLocation(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => _dismiss(context),
                  child: const Text(
                    'Concluído',
                    style: TextStyle(
                      color: SoloForteSheetSkinIos.titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: PremiumGlassPanel(
        isDark: true,
        padding: EdgeInsets.zero,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
          decoration: BoxDecoration(
            color: PremiumTokens.surfaceDark.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      const Text(
                        'Exportar localização',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coordsPreview,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _ActionRow(
                  icon: SFIcons.map,
                  title: 'Google Maps',
                  color: PremiumTokens.brandGreen,
                  onTap: () => _openExternalUrl(
                    context,
                    MapLocationExport.googleMapsUrl(latitude, longitude),
                  ),
                ),
                _ActionRow(
                  icon: SFIcons.pinFill,
                  title: 'Apple Maps',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _openExternalUrl(
                    context,
                    MapLocationExport.appleMapsUrl(latitude, longitude),
                  ),
                ),
                _ActionRow(
                  icon: SFIcons.assignment,
                  title: 'Copiar coordenadas',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _copyCoordinates(context),
                ),
                _ActionRow(
                  icon: Icons.ios_share_outlined,
                  title: 'Compartilhar',
                  color: PremiumTokens.alertWarning,
                  showDivider: false,
                  onTap: () => _shareLocation(context),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _dismiss(context),
                    child: const Text(
                      'Concluído',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isIos;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.showDivider = true,
    this.isIos = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final arrowColor = isIos
        ? SoloForteSheetSkinIos.arrowColor
        : Colors.white.withValues(alpha: 0.32);
    final dividerColor = isIos
        ? SoloForteSheetSkinIos.rowDivider
        : Colors.white.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  if (isIos) const SizedBox(width: 12),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isIos
                          ? SoloForteSheetSkinIos.iconBackground
                          : color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(isIos ? 999 : 10),
                    ),
                    child: Icon(
                      icon,
                      color: isIos ? SoloForteSheetSkinIos.iconStroke : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(SFIcons.chevronRight, color: arrowColor, size: 18),
                  if (isIos) const SizedBox(width: 12),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: isIos ? 60 : 48,
                color: dividerColor,
              ),
          ],
        ),
      ),
    );
  }
}
