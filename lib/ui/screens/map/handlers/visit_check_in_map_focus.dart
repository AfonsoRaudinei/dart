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

/// Regra de produto: produtor + (fazenda ou talhão).
bool visitCheckInNavigateToAreaEnabled({
  required String? clientId,
  required String? farmId,
  required String? talhaoId,
}) {
  if (clientId == null || clientId.isEmpty) return false;
  final hasFarm = farmId != null && farmId.isNotEmpty;
  final hasTalhao = talhaoId != null && talhaoId.isNotEmpty;
  return hasFarm || hasTalhao;
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

/// Cadastro da fazenda e polígonos desenhados no mapa (`drawings`).
///
/// O talhão escolhido sem contorno cai para o enquadramento da fazenda inteira.
List<LatLng> visitCheckInMapFocusPointsFromLinked({
  required List<FarmLinkedFieldSummary> fields,
  required String? talhaoId,
}) {
  if (talhaoId != null && talhaoId.isNotEmpty) {
    final field = fields.where((item) => item.id == talhaoId).firstOrNull;
    final selected = field == null ? const <LatLng>[] : _linkedFieldBounds(field);
    if (selected.isNotEmpty) return selected;
  }
  return fields.expand(_linkedFieldBounds).toList(growable: false);
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
  required String farmId,
  required String? talhaoId,
}) async {
  final fields = await ref.read(farmLinkedFieldsProvider(farmId).future);
  final fromFarm = visitCheckInMapFocusPointsFromLinked(
    fields: fields,
    talhaoId: talhaoId,
  );
  if (fromFarm.isNotEmpty) return fromFarm;

  final repository = ref.read(occurrenceRepositoryProvider);
  final occurrences = await repository.getOccurrencesByClientId(clientId);
  return visitCheckInMapFocusPointsFromOccurrences(occurrences);
}

String visitCheckInNoGeometryMessage(VisitCheckInMapFocusRequest request) {
  if (request.talhaoName != null && request.talhaoName!.isNotEmpty) {
    return '${request.talhaoName} sem geometria no mapa.';
  }
  if (request.farmName != null && request.farmName!.isNotEmpty) {
    return '${request.clientName} · ${request.farmName} sem geometria no mapa '
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
  }
  ref.read(selectedTalhaoIdProvider.notifier).state = request.talhaoId;

  final farmId = request.farmId;
  if (farmId == null || farmId.isEmpty) {
    return VisitCheckInMapFocusOutcome.missingFarmOrField;
  }

  final points = await resolveVisitCheckInMapFocusPoints(
    ref: ref,
    clientId: request.clientId,
    farmId: farmId,
    talhaoId: request.talhaoId,
  );
  if (points.isEmpty) {
    return VisitCheckInMapFocusOutcome.noGeometry;
  }

  mapController.fitCamera(
    CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.all(56),
    ),
  );
  ref.read(viewportStateProvider.notifier).state = InitialViewportState.applied;
  return VisitCheckInMapFocusOutcome.success;
}
