import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/contracts/i_occurrence_access_reader_provider.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../../core/session/local_session_identity.dart';
import '../../../../core/session/user_role.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/marketing/domain/entities/marketing_case.dart';
import '../../../../modules/marketing/domain/marketing_case_visibility.dart';
import '../../../../modules/marketing/presentation/providers/marketing_providers.dart';
import '../../../../modules/marketing/presentation/widgets/marketing_case_marker.dart';
import '../../../../modules/marketing/presentation/widgets/marketing_case_sheet.dart';
import '../../../../modules/settings/presentation/providers/user_profile_provider.dart';
import '../../../screens/map/providers/pin_position_correction_provider.dart';
import '../../../theme/premium/design_tokens.dart';
import '../providers/marker_providers.dart';

/// Pin arrastável sobre o mapa durante sessão de correção de posição.
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
    const pinWidth = 40.0;
    const pinHeight = 44.0;

    return Positioned(
      left: screenPoint.x - (pinWidth / 2),
      top: screenPoint.y - pinHeight,
      width: pinWidth,
      height: pinHeight,
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
        child: Icon(
          SFIcons.pinFill,
          size: 36,
          color: _isDragging
              ? PremiumTokens.brandGreen.withValues(alpha: 0.85)
              : PremiumTokens.brandGreen,
          shadows: const [
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
}

/// Markers de ocorrência com supressão do pin em correção.
class PinCorrectionAwareOccurrenceMarkersLayer extends ConsumerWidget {
  final void Function(Occurrence) onOccurrenceTap;

  const PinCorrectionAwareOccurrenceMarkersLayer({
    super.key,
    required this.onOccurrenceTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excludedId = ref.watch(
      pinPositionCorrectionProvider.select(
        (s) => s?.kind == PinCorrectionKind.occurrence ? s?.entityId : null,
      ),
    );

    final markers = ref.watch(occurrenceMarkersProvider(onOccurrenceTap));
    final filtered = excludedId == null
        ? markers
        : markers
              .where((marker) {
                final key = marker.key;
                if (key is ValueKey<String>) {
                  return key.value != 'occ_$excludedId';
                }
                return true;
              })
              .toList(growable: false);

    final showMarkers = ref.watch(showMarkersProvider);
    if (!showMarkers || filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 100,
        size: const Size(40, 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40),
        maxZoom: 15,
        markers: filtered,
        builder: (context, clusterMarkers) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.orange.shade700,
            ),
            child: Center(
              child: Text(
                clusterMarkers.length.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Markers de marketing com supressão do pin em correção.
class PinCorrectionAwareMarketingMarkersLayer extends ConsumerWidget {
  const PinCorrectionAwareMarketingMarkersLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMarkers = ref.watch(showMarkersProvider);
    if (!showMarkers) return const SizedBox.shrink();

    final excludedId = ref.watch(
      pinPositionCorrectionProvider.select(
        (s) => s?.kind == PinCorrectionKind.marketing ? s?.entityId : null,
      ),
    );

    final snapshotZoom = ref.watch(
      mapCameraSnapshotProvider.select((s) => s?.zoom),
    );
    final currentZoom =
        snapshotZoom ?? MapCamera.maybeOf(context)?.zoom ?? 0.0;
    final role = ref.watch(currentUserRoleProvider);
    final isProdutor = role.isProdutor;
    final currentUserId = LocalSessionIdentity.resolveUserId();
    final authorized =
        isProdutor
            ? (ref.watch(authorizedClientIdsProvider).valueOrNull ??
                  const <String>{})
            : const <String>{};

    final publishedCases = ref.watch(
      marketingCasesProvider.select((async) {
        if (!async.hasValue) return const <MarketingCase>[];
        return async.value!
            .where(
              (c) =>
                  c.status.toValue() == 'published' &&
                  c.ativo &&
                  c.deletadoEm == null &&
                  (excludedId == null || c.id != excludedId),
            )
            .toList(growable: false);
      }),
    );

    final cases = (isProdutor
            ? publishedCases.where(
                (c) => MarketingCaseVisibility.isVisibleOnMapForProducer(
                  marketingCase: c,
                  currentUserId: currentUserId,
                  authorizedClientIds: authorized,
                ),
              )
            : publishedCases)
        .toList()
      ..sort((a, b) => b.visibilidade.index.compareTo(a.visibilidade.index));

    if (cases.isEmpty) return const SizedBox.shrink();

    final visibleCases = cases
        .where((c) {
          final tier = c.visibilidade;
          return MarketingCaseMarker.isVisibleAtZoom(tier, currentZoom);
        })
        .toList(growable: false);

    if (visibleCases.isEmpty) return const SizedBox.shrink();

    return MarkerLayer(
      rotate: true,
      markers: visibleCases
          .map(
            (mCase) => Marker(
              key: ValueKey('mkt_${mCase.id}'),
              point: LatLng(mCase.lat, mCase.lng),
              width: MarketingCaseMarker.pinWidth(mCase.visibilidade),
              height: MarketingCaseMarker.pinHeight(mCase.visibilidade) + 10,
              alignment: Alignment.topCenter,
              child: MarketingCaseMarker(
                marketingCase: mCase,
                onTap: () {
                  HapticFeedback.lightImpact();
                  MarketingCaseSheet.show(context, mCase);
                },
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
