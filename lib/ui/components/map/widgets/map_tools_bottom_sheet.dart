import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../modules/drawing/presentation/controllers/drawing_controller.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_sheet.dart';
import '../../../theme/premium/design_tokens.dart';
import '../map_layers_sheet.dart';

class MapToolsBottomSheet extends StatefulWidget {
  final DrawingController drawingController;
  final Future<void> Function()? onCoordinateSearch;
  final Future<void> Function()? onMunicipalitySearch;
  final Future<void> Function()? onDownloadOfflineArea;

  const MapToolsBottomSheet({
    super.key,
    required this.drawingController,
    this.onCoordinateSearch,
    this.onMunicipalitySearch,
    this.onDownloadOfflineArea,
  });

  static Future<void> show({
    required BuildContext context,
    required DrawingController drawingController,
    Future<void> Function()? onCoordinateSearch,
    Future<void> Function()? onMunicipalitySearch,
    Future<void> Function()? onDownloadOfflineArea,
  }) {
    return showSoloForteSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      maxHeightFraction: 0.78,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      builder: (_) => MapToolsBottomSheet(
        drawingController: drawingController,
        onCoordinateSearch: onCoordinateSearch,
        onMunicipalitySearch: onMunicipalitySearch,
        onDownloadOfflineArea: onDownloadOfflineArea,
      ),
    );
  }

  @override
  State<MapToolsBottomSheet> createState() => _MapToolsBottomSheetState();
}

class _MapToolsBottomSheetState extends State<MapToolsBottomSheet> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.78;
    final isIos = soloForteSheetIsIos(context);
    final bg = isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
    final radius = isIos
        ? SoloForteSheetSkinIos.sheetRadius
        : SoloForteSheetTokens.borderRadius;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _SegmentedHeader(
                    selectedIndex: _selectedIndex,
                    onSelected: _selectTab,
                    isIos: isIos,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _selectedIndex == 0
                      ? DrawingSheet(
                          controller: widget.drawingController,
                          onClose: () => Navigator.of(
                            context,
                            rootNavigator: false,
                          ).pop(),
                          onSaved: () => Navigator.of(
                            context,
                            rootNavigator: false,
                          ).pop(),
                        )
                      : LayersSheet(
                          onClose: () => Navigator.of(
                            context,
                            rootNavigator: false,
                          ).pop(),
                          onCoordinateSearch: widget.onCoordinateSearch,
                          onMunicipalitySearch: widget.onMunicipalitySearch,
                          onDownloadOfflineArea: widget.onDownloadOfflineArea,
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

class _SegmentedHeader extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isIos;

  const _SegmentedHeader({
    required this.selectedIndex,
    required this.onSelected,
    required this.isIos,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor =
        isIos ? SoloForteSheetSkinIos.cardBackground : const Color(0xFF2C2C2E);
    final trackBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : Colors.white.withValues(alpha: 0.08);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: trackBorder, width: 0.5),
      ),
      child: Row(
        children: [
          _SegmentButton(
            icon: SFIcons.edit,
            label: 'Desenho',
            isSelected: selectedIndex == 0,
            onTap: () => onSelected(0),
            isIos: isIos,
          ),
          _SegmentButton(
            icon: SFIcons.layers,
            label: 'Visualização',
            isSelected: selectedIndex == 1,
            onTap: () => onSelected(1),
            isIos: isIos,
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isIos;

  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isIos,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : PremiumTokens.brandGreen;
    final idleLabel =
        isIos ? SoloForteSheetSkinIos.subtitleColor : const Color(0xFFAEAEB2);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: isSelected && !isIos
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isSelected ? Colors.white : idleLabel,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : idleLabel,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
