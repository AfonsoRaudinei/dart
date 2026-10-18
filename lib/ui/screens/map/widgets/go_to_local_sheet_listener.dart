import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/map_ui_providers.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../../components/map/map_go_to_local_sheet.dart';

/// Consome [pendingGoToLocalSheetProvider] no mount e em mudanças posteriores.
class GoToLocalSheetListener extends ConsumerStatefulWidget {
  final Widget child;
  final Future<void> Function() onMunicipalitySearch;
  final Future<void> Function() onCoordinateSearch;
  final VoidCallback? onBeforeOpen;

  const GoToLocalSheetListener({
    super.key,
    required this.child,
    required this.onMunicipalitySearch,
    required this.onCoordinateSearch,
    this.onBeforeOpen,
  });

  @override
  ConsumerState<GoToLocalSheetListener> createState() =>
      _GoToLocalSheetListenerState();
}

class _GoToLocalSheetListenerState extends ConsumerState<GoToLocalSheetListener> {
  static const _editingBlockedMessage =
      'Finalize a edição do talhão para ir para outro local';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainPendingIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(pendingGoToLocalSheetProvider, (previous, next) {
      if (!next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _drainPendingIfNeeded());
    });
    return widget.child;
  }

  void _drainPendingIfNeeded() {
    if (!mounted) return;
    if (!ref.read(pendingGoToLocalSheetProvider)) return;

    if (ref.read(drawingControllerProvider).currentState ==
        DrawingState.editing) {
      ref.read(pendingGoToLocalSheetProvider.notifier).state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_editingBlockedMessage),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    ref.read(pendingGoToLocalSheetProvider.notifier).state = false;
    widget.onBeforeOpen?.call();
    showMapGoToLocalSheet(
      context,
      onMunicipalitySearch: widget.onMunicipalitySearch,
      onCoordinateSearch: widget.onCoordinateSearch,
    );
  }
}
