import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/state/map_ui_providers.dart';
import '../../../../modules/consultoria/clients/domain/agronomic_models.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../../../modules/drawing/presentation/providers/drawing_client_provider.dart';

/// Pedido de foco no mapa a partir do sheet Iniciar Visita (sem iniciar sessão).
class VisitCheckInMapFocusRequest {
  const VisitCheckInMapFocusRequest({
    required this.clientId,
    required this.clientName,
    this.farmId,
    this.farmName,
    this.talhaoId,
    this.talhaoName,
  });

  final String clientId;
  final String clientName;
  final String? farmId;
  final String? farmName;
  final String? talhaoId;
  final String? talhaoName;
}

enum VisitCheckInMapFocusOutcome {
  success,
  missingFarmOrField,
  noGeometry,
}

typedef VisitCheckInNavigateToAreaCallback =
    void Function(
      String clientId,
      String clientName,
      String? farmId,
      String? farmName,
      String? talhaoId,
      String? talhaoName,
    );

final visitCheckInMapFocusRequestProvider =
    StateProvider.autoDispose<VisitCheckInMapFocusRequest?>((ref) => null);

void queueVisitCheckInMapFocus(
  WidgetRef ref, {
  required String clientId,
  required String clientName,
  String? farmId,
  String? farmName,
  String? talhaoId,
  String? talhaoName,
}) {
  ref.read(visitCheckInMapFocusRequestProvider.notifier).state =
      VisitCheckInMapFocusRequest(
        clientId: clientId,
        clientName: clientName,
        farmId: farmId,
        farmName: farmName,
        talhaoId: talhaoId,
        talhaoName: talhaoName,
      );
}

VisitCheckInNavigateToAreaCallback buildVisitCheckInNavigateHandler(
  WidgetRef ref,
  VoidCallback closeSheet,
) {
  return (
    String clientId,
    String clientName,
    String? farmId,
    String? farmName,
    String? talhaoId,
    String? talhaoName,
  ) {
    queueVisitCheckInMapFocus(
      ref,
      clientId: clientId,
      clientName: clientName,
      farmId: farmId,
      farmName: farmName,
      talhaoId: talhaoId,
      talhaoName: talhaoName,
    );
    closeSheet();
  };
}

/// Regra de produto: basta o produtor selecionado (usa fazenda/talhão se
/// houver, ou busca desenhos e ocorrências do produtor).
bool visitCheckInNavigateToAreaEnabled({
  required String? clientId,
  required String? farmId,
  required String? talhaoId,
}) {
  return clientId != null && clientId.trim().isNotEmpty;
}

/// Pontos para [CameraFit.bounds] — talhão único ou união dos talhões da fazenda.
List<LatLng> visitCheckInMapFocusSamplePoints({
  required List<Talhao> farmFields,
  required String? talhaoId,
}) {
  if (talhaoId != null && talhaoId.isNotEmpty) {
    final field = farmFields.where((f) => f.id == talhaoId).firstOrNull;
    if (field == null) return const [];
    return TalhaoMapAdapter.boundsSamplePoints(field);
  }
  return farmFields
      .expand(TalhaoMapAdapter.boundsSamplePoints)
      .toList(growable: false);
}

List<LatLng> _linkedFieldBounds(FarmLinkedFieldSummary field) {
  if (field.boundsVertices.isNotEmpty) return field.boundsVertices;
  return field.vertices;
}

List<FarmLinkedFieldSummary> _drawingsWithMapBounds(
  Iterable<FarmLinkedFieldSummary> fields,
) {
  return fields
      .where((field) => field.isDrawing && farmLinkedFieldHasBounds(field))
      .toList(growable: false);
}

List<LatLng> _boundsFromDrawingSummaries(
  Iterable<FarmLinkedFieldSummary> fields,
) {
  return fields.expand(_linkedFieldBounds).toList(growable: false);
}

List<LatLng> visitCheckInMapFocusPointsFromClientDrawings(
  Iterable<ClientDrawingFieldSummary> fields,
) {
  return fields
      .where(
        (field) => field.boundsVertices.isNotEmpty || field.vertices.isNotEmpty,
      )
      .expand(
        (field) => field.boundsVertices.isNotEmpty
            ? field.boundsVertices
            : field.vertices,
      )
      .toList(growable: false);
}

/// Polígonos desenhados no mapa (`drawings`) vinculados à fazenda.
///
/// Geometria só de cadastro não conta — cai para desenhos avulsos do produtor
/// e depois ocorrências em [resolveVisitCheckInMapFocusPoints].
/// Talhão sem contorno desenhado enquadra todos os polígonos da fazenda.
List<LatLng> visitCheckInMapFocusPointsFromLinked({
  required List<FarmLinkedFieldSummary> fields,
  required String? talhaoId,
}) {
  final drawings = _drawingsWithMapBounds(fields);
  if (talhaoId != null && talhaoId.isNotEmpty) {
    final selectedDrawing =
        drawings.where((item) => item.id == talhaoId).firstOrNull;
    if (selectedDrawing != null) {
      return _linkedFieldBounds(selectedDrawing);
    }
    if (drawings.isNotEmpty) {
      return _boundsFromDrawingSummaries(drawings);
    }
    return const [];
  }
  return _boundsFromDrawingSummaries(drawings);
}

/// Pins de ocorrências registradas para o produtor (lat/long ou GeoJSON Point).
List<LatLng> visitCheckInMapFocusPointsFromOccurrences(
  Iterable<Occurrence> occurrences,
) {
  final points = <LatLng>[];
  for (final occurrence in occurrences) {
    final coords = occurrence.getCoordinates();
    if (coords == null) continue;
    points.add(LatLng(coords['lat']!, coords['long']!));
  }
  return points;
}

Future<List<LatLng>> resolveVisitCheckInMapFocusPoints({
  required WidgetRef ref,
  required String clientId,
  required String? farmId,
  required String? talhaoId,
}) async {
  if (farmId != null && farmId.isNotEmpty) {
    final fields = await ref.read(farmLinkedFieldsProvider(farmId).future);
    final fromFarm = visitCheckInMapFocusPointsFromLinked(
      fields: fields,
      talhaoId: talhaoId,
    );
    if (fromFarm.isNotEmpty) return fromFarm;
  }

  final clientDrawings = await ref.read(
    clientAllDrawingFieldsProvider(clientId).future,
  );
  final fromClientDrawings = visitCheckInMapFocusPointsFromClientDrawings(
    clientDrawings,
  );
  if (fromClientDrawings.isNotEmpty) return fromClientDrawings;

  final repository = ref.read(occurrenceRepositoryProvider);
  final occurrences = await repository.getOccurrencesForClientMapFocus(clientId);
  return visitCheckInMapFocusPointsFromOccurrences(occurrences);
}

/// Move ou enquadra a câmera nos pontos resolvidos.
///
/// Quando há apenas 1 ponto (ex.: 1 pin de ocorrência) ou pontos idênticos,
/// evita `CameraFit.bounds` com bbox degenerada (span ~ 0) e usa `move`.
bool fitVisitFocusPointsOnMap(
  MapController mapController,
  List<LatLng> points,
) {
  if (points.isEmpty) return false;
  final bounds = LatLngBounds.fromPoints(points);
  final isSinglePoint =
      (bounds.north - bounds.south).abs() < 1e-5 &&
      (bounds.east - bounds.west).abs() < 1e-5;
  if (isSinglePoint) {
    mapController.move(bounds.center, 16.0);
    return true;
  }
  mapController.fitCamera(
    CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(56),
      maxZoom: 17.0,
    ),
  );
  return true;
}

String visitCheckInNoGeometryMessage(VisitCheckInMapFocusRequest request) {
  if (request.talhaoName != null && request.talhaoName!.isNotEmpty) {
    return '${request.talhaoName} sem geometria no mapa '
        'nem ocorrências com localização.';
  }
  if (request.farmName != null && request.farmName!.isNotEmpty) {
    return '${request.clientName} · ${request.farmName} sem geometria no mapa '
        'nem ocorrências com localização.';
  }
  if (request.clientName.trim().isNotEmpty) {
    return '${request.clientName} sem área desenhada no mapa '
        'nem ocorrências com localização.';
  }
  return 'Área selecionada sem geometria no mapa '
      'nem ocorrências com localização.';
}

Future<VisitCheckInMapFocusOutcome> applyVisitCheckInMapFocusRequest({
  required WidgetRef ref,
  required MapController mapController,
  required VisitCheckInMapFocusRequest request,
}) async {
  if (request.clientId.trim().isEmpty) {
    return VisitCheckInMapFocusOutcome.missingFarmOrField;
  }

  ref.read(explicitMapCameraIntentProvider.notifier).state = true;
  ref
      .read(drawingClientProvider.notifier)
      .setClienteAtivo(
        request.clientId,
        clientName: request.clientName,
        farmId: request.farmId,
        farmName: request.farmName,
      );

  if (request.farmId != null && request.farmId!.isNotEmpty) {
    ref.read(selectedFarmIdProvider.notifier).state = request.farmId;
  } else {
    ref.read(selectedFarmIdProvider.notifier).state = null;
  }
  ref.read(selectedTalhaoIdProvider.notifier).state = request.talhaoId;

  final points = await resolveVisitCheckInMapFocusPoints(
    ref: ref,
    clientId: request.clientId,
    farmId: request.farmId,
    talhaoId: request.talhaoId,
  );
  if (!fitVisitFocusPointsOnMap(mapController, points)) {
    return VisitCheckInMapFocusOutcome.noGeometry;
  }

  ref.read(viewportStateProvider.notifier).state = InitialViewportState.applied;
  return VisitCheckInMapFocusOutcome.success;
}
