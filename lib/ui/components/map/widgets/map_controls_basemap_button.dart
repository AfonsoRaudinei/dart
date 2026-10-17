part of 'map_controls_overlay.dart';

class _MapBasemapToggleButton extends ConsumerStatefulWidget {
  final Color activeColor;

  const _MapBasemapToggleButton({required this.activeColor});

  @override
  ConsumerState<_MapBasemapToggleButton> createState() =>
      _MapBasemapToggleButtonState();
}

class _MapBasemapToggleButtonState extends ConsumerState<_MapBasemapToggleButton> {
  Timer? _labelTimer;
  bool _showLabel = false;

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  void _showTemporaryLabel() {
    _labelTimer?.cancel();
    setState(() => _showLabel = true);
    _labelTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showLabel = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final layer = ref.watch(activeLayerProvider);
    final isSatellite = layer == LayerType.satellite;
    final label = isSatellite ? 'Satélite' : 'Mapa';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButtonLabel(text: label, isVisible: _showLabel),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: label,
          child: _MapRoundToggleButton(
            buttonKey: const Key('map_control_basemap_toggle'),
            icon: isSatellite ? SFIcons.satellite : SFIcons.mapOutlined,
            iconColor: widget.activeColor,
            isOn: true,
            showSlash: false,
            onTap: () {
              HapticFeedback.selectionClick();
              final next = isSatellite ? LayerType.standard : LayerType.satellite;
              ref.read(activeLayerProvider.notifier).setLayer(next);
            },
            onLongPress: _showTemporaryLabel,
          ),
        ),
      ],
    );
  }
}
