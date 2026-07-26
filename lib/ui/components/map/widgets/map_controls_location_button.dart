part of 'map_controls_overlay.dart';

class _LocationButton extends ConsumerStatefulWidget {
  final void Function({bool lockNorth}) onCenterUser;
  final ValueChanged<MapLocationMode> onLocationModeChanged;
  final Color activeColor;

  const _LocationButton({
    required this.onCenterUser,
    required this.onLocationModeChanged,
    required this.activeColor,
  });

  @override
  ConsumerState<_LocationButton> createState() => _LocationButtonState();
}

class _LocationButtonState extends ConsumerState<_LocationButton> {
  Timer? _labelTimer;
  bool _showLabel = false;
  String _labelText = 'Localização';

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  void _showTemporaryLabel(String text) {
    _labelTimer?.cancel();
    setState(() {
      _labelText = text;
      _showLabel = true;
    });
    _labelTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _showLabel = false);
      }
    });
  }

  static String _labelForMode(MapLocationMode mode) {
    return switch (mode) {
      MapLocationMode.idle => 'Localização',
      MapLocationMode.following => 'Minha localização',
      MapLocationMode.northLocked => 'Norte travado',
    };
  }

  @override
  Widget build(BuildContext context) {
    final locationMode = ref.watch(mapLocationModeProvider);
    final locationState = ref.watch(locationStateProvider);
    final isAvailable = locationState == LocationState.available;
    final isActive = locationMode != MapLocationMode.idle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButtonLabel(text: _labelText, isVisible: _showLabel),
        const SizedBox(width: 8),
        Tooltip(
          message: _labelForMode(locationMode),
          waitDuration: const Duration(milliseconds: 450),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();

                final nextMode = switch (locationMode) {
                  MapLocationMode.idle => MapLocationMode.following,
                  MapLocationMode.following => MapLocationMode.northLocked,
                  MapLocationMode.northLocked => MapLocationMode.idle,
                };

                _showTemporaryLabel(_labelForMode(nextMode));

                ref.read(mapLocationModeProvider.notifier).state = nextMode;
                widget.onLocationModeChanged(nextMode);

                if (nextMode == MapLocationMode.following) {
                  widget.onCenterUser();
                } else if (nextMode == MapLocationMode.northLocked) {
                  widget.onCenterUser(lockNorth: true);
                }

                AppLogger.debug(
                  'MapOverlay: Modo de localização mudou para $nextMode',
                  tag: 'MapControls',
                );
              },
              onLongPress: () =>
                  _showTemporaryLabel(_labelForMode(locationMode)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _iconForMode(locationMode),
                  size: 22,
                  color: isAvailable
                      ? isActive
                            ? widget.activeColor
                            : Colors.grey.shade600
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForMode(MapLocationMode mode) {
    return switch (mode) {
      MapLocationMode.idle => Icons.navigation_outlined,
      MapLocationMode.following => Icons.navigation,
      MapLocationMode.northLocked => Icons.explore,
    };
  }
}
