part of 'map_controls_overlay.dart';

/// Indicador compacto quando um talhão/feature está selecionado (modo compact).
class _SelectedFeatureChromeIndicator extends StatefulWidget {
  const _SelectedFeatureChromeIndicator({required this.activeColor});

  final Color activeColor;

  @override
  State<_SelectedFeatureChromeIndicator> createState() =>
      _SelectedFeatureChromeIndicatorState();
}

class _SelectedFeatureChromeIndicatorState
    extends State<_SelectedFeatureChromeIndicator> {
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
    const label = 'Feature selecionada';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButtonLabel(text: label, isVisible: _showLabel),
        const SizedBox(width: kMapTopControlsLocationLabelButtonGap),
        Semantics(
          label: label,
          child: _MapRoundToggleButton(
            buttonKey: const Key('map_control_selected_feature_indicator'),
            icon: Icons.crop_free,
            iconColor: Colors.teal.shade600,
            isOn: true,
            onLongPress: _showTemporaryLabel,
          ),
        ),
      ],
    );
  }
}
