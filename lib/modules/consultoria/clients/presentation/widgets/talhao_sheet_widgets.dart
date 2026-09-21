import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_form_padding.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_linked_field_list.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Tokens visuais compartilhados pelos sheets de talhão (premium iOS).
class TalhaoSheetVisuals {
  TalhaoSheetVisuals._(this.context);

  factory TalhaoSheetVisuals.of(BuildContext context) =>
      TalhaoSheetVisuals._(context);

  final BuildContext context;

  bool get isIos => soloForteSheetIsIos(context);

  Color get sheetBg => isIos ? Colors.transparent : Colors.white;

  double get sheetRadius => isIos ? SoloForteSheetSkinIos.sheetRadius : 24.0;

  Color? get titleColor =>
      isIos ? SoloForteSheetSkinIos.titleColor : null;

  Color get muted =>
      isIos ? SoloForteSheetSkinIos.subtitleColor : SoloForteSheetTokens.inputHint;

  Color get accent =>
      isIos ? SoloForteSheetSkinIos.iconStroke : PremiumTokens.brandGreen;

  Color get cardBg =>
      isIos ? SoloForteSheetSkinIos.cardBackground : const Color(0xFFEFFAF2);

  Color get cardBorder =>
      isIos ? SoloForteSheetSkinIos.cardBorder : const Color(0xFFE2E2E8);

  double get cardRadius => isIos ? SoloForteSheetSkinIos.cardRadius : 16.0;

  Color get arrowColor =>
      isIos ? SoloForteSheetSkinIos.arrowColor : const Color(0xFFC7C7CC);

  Color get dividerColor =>
      isIos ? SoloForteSheetSkinIos.rowDivider : const Color(0xFFE5E5EA);

  Color get ctaBg =>
      isIos ? SoloForteSheetSkinIos.ctaBackground : PremiumTokens.brandGreen;

  Color get ctaFg => isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;

  double get ctaRadius => isIos ? SoloForteSheetSkinIos.ctaRadius : 13.0;

  Color get ghostBorder =>
      isIos ? SoloForteSheetSkinIos.ghostBorder : const Color(0xFFE2E2E8);

  Color get ghostText =>
      isIos ? SoloForteSheetSkinIos.ghostText : PremiumTokens.brandGreen;

  double get ghostRadius => isIos ? SoloForteSheetSkinIos.ghostRadius : 13.0;

  Color get inputFill =>
      isIos ? SoloForteSheetSkinIos.cardBackground : SoloForteSheetTokens.inputBackground;

  Color get inputText =>
      isIos ? SoloForteSheetSkinIos.titleColor : SoloForteSheetTokens.inputText;

  Color get inputHint =>
      isIos ? SoloForteSheetSkinIos.subtitleColor : SoloForteSheetTokens.inputHint;
}

/// Scaffold padrão: handle, título, subtítulo opcional e corpo.
class TalhaoSheetScaffold extends StatelessWidget {
  const TalhaoSheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.contextLine,
    this.showHandle = true,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final String? contextLine;
  final bool showHandle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.sheetBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(visuals.sheetRadius),
        ),
      ),
      child: Padding(
        padding: clientSheetFormPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) ...[
              Center(
                child: Container(
                  width: visuals.isIos
                      ? SoloForteSheetSkinIos.handleSize.width
                      : 36,
                  height: visuals.isIos
                      ? SoloForteSheetSkinIos.handleSize.height
                      : 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: visuals.isIos
                        ? SoloForteSheetSkinIos.handleColor
                        : const Color(0xFFC5C5C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: visuals.titleColor,
              ),
            ),
            if (contextLine != null && contextLine!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                contextLine!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: visuals.muted),
              ),
            ],
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 13, color: visuals.muted),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Card agrupado com rows de ação estilo iOS.
class TalhaoSheetActionCard extends StatelessWidget {
  const TalhaoSheetActionCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.cardBg,
        borderRadius: BorderRadius.circular(visuals.cardRadius),
        border: Border.all(color: visuals.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class TalhaoSheetActionRow extends StatelessWidget {
  const TalhaoSheetActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: visuals.isIos
                          ? SoloForteSheetSkinIos.iconBackground
                          : visuals.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        visuals.isIos
                            ? SoloForteSheetSkinIos.iconRadius
                            : 12,
                      ),
                    ),
                    child: Icon(icon, color: visuals.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: visuals.titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: visuals.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: visuals.arrowColor, size: 18),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 60,
            color: visuals.dividerColor,
          ),
      ],
    );
  }
}

class TalhaoSheetSectionLabel extends StatelessWidget {
  const TalhaoSheetSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: visuals.titleColor,
        ),
      ),
    );
  }
}

class TalhaoSheetFormField extends StatelessWidget {
  const TalhaoSheetFormField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);

    final field = TextFormField(
      controller: controller,
      autofocus: autofocus,
      validator: validator,
      style: TextStyle(color: visuals.inputText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: visuals.inputHint),
        filled: true,
        fillColor: visuals.inputFill,
        contentPadding: SoloForteSheetTokens.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(visuals.cardRadius),
          borderSide: BorderSide(color: visuals.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(visuals.cardRadius),
          borderSide: BorderSide(color: visuals.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(visuals.cardRadius),
          borderSide: BorderSide(color: visuals.accent, width: 1.5),
        ),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TalhaoSheetSectionLabel(label: label!),
        field,
      ],
    );
  }
}

class TalhaoSheetButtonRow extends StatelessWidget {
  const TalhaoSheetButtonRow({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    this.isSaving = false,
    this.confirmEnabled = true,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final bool isSaving;
  final bool confirmEnabled;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);
    final enabled = confirmEnabled && !isSaving;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: visuals.ghostText,
              side: BorderSide(color: visuals.ghostBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visuals.ghostRadius),
              ),
            ),
            onPressed: isSaving ? null : onCancel,
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: visuals.ctaBg,
              foregroundColor: visuals.ctaFg,
              disabledBackgroundColor: visuals.ctaBg.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visuals.ctaRadius),
              ),
            ),
            onPressed: enabled ? onConfirm : null,
            child: isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: visuals.ctaFg,
                    ),
                  )
                : Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}

class TalhaoSheetFarmSkeleton extends StatelessWidget {
  const TalhaoSheetFarmSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: visuals.inputFill,
        borderRadius: BorderRadius.circular(visuals.cardRadius),
        border: Border.all(color: visuals.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 10,
            width: 120,
            decoration: BoxDecoration(
              color: visuals.muted.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 180,
            decoration: BoxDecoration(
              color: visuals.muted.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini preview de polígono para listas de união.
class TalhaoPolygonThumb extends StatelessWidget {
  const TalhaoPolygonThumb({
    super.key,
    required this.vertices,
    this.size = 48,
  });

  final List<LatLng> vertices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);
    final radius = visuals.isIos ? 10.0 : 8.0;

    if (vertices.length < 3) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: visuals.cardBorder),
        ),
        child: Icon(Icons.map_outlined, size: 20, color: visuals.muted),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(vertices),
              padding: const EdgeInsets.all(6),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileConfigForLayer(
                LayerType.satellite,
                mapTilerApiKey: MapConfig.mapTilerApiKey,
              ).urlTemplate,
              subdomains: MapConfig.tileConfigForLayer(
                LayerType.satellite,
                mapTilerApiKey: MapConfig.mapTilerApiKey,
              ).subdomains,
              maxZoom: 18,
              userAgentPackageName: MapConfig.userAgent,
            ),
            PolygonLayer(
              polygons: [
                Polygon(
                  points: vertices,
                  color: visuals.accent.withValues(alpha: 0.35),
                  borderColor: visuals.accent,
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TalhaoSheetPrimaryChip extends StatelessWidget {
  const TalhaoSheetPrimaryChip({
    super.key,
    required this.name,
    required this.areaHa,
    this.vertices = const [],
  });

  final String name;
  final double areaHa;
  final List<LatLng> vertices;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: visuals.cardBg,
        borderRadius: BorderRadius.circular(visuals.cardRadius),
        border: Border.all(color: visuals.accent, width: 1.5),
      ),
      child: Row(
        children: [
          TalhaoPolygonThumb(vertices: vertices, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talhão principal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: visuals.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: visuals.titleColor,
                  ),
                ),
                Text(
                  '${formatLinkedFieldAreaHa(areaHa)} ha',
                  style: TextStyle(fontSize: 13, color: visuals.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TalhaoUnionCandidateRow extends StatelessWidget {
  const TalhaoUnionCandidateRow({
    super.key,
    required this.name,
    required this.areaHa,
    required this.vertices,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final String name;
  final double areaHa;
  final List<LatLng> vertices;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final visuals = TalhaoSheetVisuals.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 22,
                    color: selected ? visuals.accent : visuals.muted,
                  ),
                  const SizedBox(width: 10),
                  TalhaoPolygonThumb(vertices: vertices, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: visuals.titleColor,
                          ),
                        ),
                        Text(
                          '${formatLinkedFieldAreaHa(areaHa)} ha',
                          style: TextStyle(fontSize: 13, color: visuals.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 44,
            color: visuals.dividerColor,
          ),
      ],
    );
  }
}

String buildTalhaoContextLine({
  required double areaHa,
  String? cultura,
  String? safra,
}) {
  final parts = <String>['${formatLinkedFieldAreaHa(areaHa)} ha'];
  if (cultura != null && cultura.trim().isNotEmpty) {
    parts.add(cultura.trim());
  } else if (safra != null && safra.trim().isNotEmpty) {
    parts.add('Safra ${safra.trim()}');
  }
  return parts.join(' · ');
}
