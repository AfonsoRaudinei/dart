import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../theme/premium/design_tokens.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../../modules/marketing/domain/entities/marketing_case.dart';
import '../../../../modules/marketing/domain/enums/plano_marketing.dart';
import '../../../../modules/marketing/presentation/providers/marketing_providers.dart';
import '../../../../modules/marketing/presentation/widgets/marketing_case_marker.dart';
import '../../../screens/map/providers/pin_position_correction_provider.dart';
import '../occurrence_pins.dart';
import 'pin_correction_screen_anchor.dart';

/// Pin arrastável sobre o mapa durante sessão de correção de posição.
///
/// Renderiza o mesmo visual e a mesma âncora do marker definitivo no mapa.
class DraggablePinLayer extends ConsumerStatefulWidget {
  final MapController mapController;

  const DraggablePinLayer({super.key, required this.mapController});

  @override
  ConsumerState<DraggablePinLayer> createState() => _DraggablePinLayerState();
}

class _DraggablePinLayerState extends ConsumerState<DraggablePinLayer> {
  bool _isDragging = false;

  void _handlePanUpdate(DragUpdateDetails details, LatLng basePoint) {
    final screenPoint = widget.mapController.camera.latLngToScreenPoint(
      basePoint,
    );
    final movedPoint = math.Point<double>(
      screenPoint.x + details.delta.dx,
      screenPoint.y + details.delta.dy,
    );
    final newLatLng = widget.mapController.camera.pointToLatLng(movedPoint);
    ref.updatePinCorrectionCurrent(newLatLng);
  }

  OccurrenceMarkerData? _occurrencePreview(PinPositionCorrectionSession session) {
    final occurrences = ref.watch(
      occurrencesListProvider.select(
        (asyncOcc) => asyncOcc.hasValue ? asyncOcc.value! : null,
      ),
    );
    if (occurrences == null) return null;

    for (final occurrence in occurrences) {
      if (occurrence.id != session.entityId) continue;
      final projection = OccurrencePinGenerator.projectOccurrences([occurrence]);
      if (projection.markers.isEmpty) return null;
      return projection.markers.first;
    }
    return null;
  }

  MarketingCase? _marketingPreview(PinPositionCorrectionSession session) {
    final cases = ref.watch(
      marketingCasesProvider.select(
        (asyncCases) => asyncCases.hasValue ? asyncCases.value! : null,
      ),
    );
    if (cases == null) return null;

    for (final marketingCase in cases) {
      if (marketingCase.id == session.entityId) return marketingCase;
    }
    return null;
  }

  Widget _buildOccurrencePreview(OccurrenceMarkerData data) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _isDragging ? 0.82 : 1,
      child: OccurrenceMapPin(data: data),
    );
  }

  Widget _buildMarketingPreview(MarketingCase marketingCase) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _isDragging ? 0.82 : 1,
      child: IgnorePointer(
        child: MarketingCaseMarker(
          marketingCase: marketingCase,
          onTap: () {},
        ),
      ),
    );
  }

  Widget _buildMarketingPinFallback() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _isDragging ? 0.82 : 1,
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Icon(
          SFIcons.pinFill,
          size: 36,
          color: PremiumTokens.brandGreen,
          shadows: [
            Shadow(
              color: Color(0x66000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  OccurrenceMarkerData _fallbackOccurrencePreview(
    PinPositionCorrectionSession session,
  ) {
    final current = session.current;
    final occurrence = Occurrence(
      id: session.entityId,
      type: '',
      description: '',
      lat: current.latitude,
      long: current.longitude,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    return OccurrenceMarkerData(
      id: session.entityId,
      occurrence: occurrence,
      position: current,
      category: occurrence.category,
      urgency: occurrence.type,
      status: occurrence.status ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pinPositionCorrectionProvider);
    if (session == null) return const SizedBox.shrink();

    final current = ref.watch(
      pinPositionCorrectionProvider.select((s) => s?.current),
    );
    if (current == null) return const SizedBox.shrink();

    // Reposiciona o pin quando a câmera move (pan/zoom).
    ref.watch(mapCameraSnapshotProvider);

    final screenPoint = widget.mapController.camera.latLngToScreenPoint(
      current,
    );

    final marketingCase = session.kind == PinCorrectionKind.marketing
        ? _marketingPreview(session)
        : null;

    final layout = layoutPinCorrectionOnScreen(
      kind: session.kind,
      screenX: screenPoint.x,
      screenY: screenPoint.y,
      marketingTier: marketingCase?.visibilidade ?? PlanoMarketing.bronze,
    );

    final Widget preview;
    switch (session.kind) {
      case PinCorrectionKind.occurrence:
        final data =
            _occurrencePreview(session) ?? _fallbackOccurrencePreview(session);
        preview = _buildOccurrencePreview(data);
      case PinCorrectionKind.marketing:
        preview = marketingCase != null
            ? _buildMarketingPreview(marketingCase)
            : _buildMarketingPinFallback();
    }

    return Positioned(
      left: layout.left,
      top: layout.top,
      width: layout.width,
      height: layout.height,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
          HapticFeedback.selectionClick();
        },
        onPanUpdate: (details) {
          final base = ref.read(pinPositionCorrectionProvider)!.current;
          _handlePanUpdate(details, base);
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        onPanCancel: () => setState(() => _isDragging = false),
        child: preview,
      ),
    );
  }
}
