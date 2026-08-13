import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../components/map/map_sheet_state.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../modules/drawing/presentation/providers/drawing_provider.dart';

/// Aplica comandos contextuais recebidos por `/map?...`.
///
/// O chamador controla idempotência por URI para evitar reabrir sheets durante
/// rebuilds normais do mapa.
class MapFirstQueryHandler {
  const MapFirstQueryHandler._();

  static void handle({
    required Uri uri,
    required WidgetRef ref,
    required void Function(MapSheetState state, String reason) setSheetState,
    required VoidCallback armOccurrenceMode,
    required Future<void> Function(String drawingId, {required bool edit})
    focusDrawing,
    required void Function(LatLng point) focusCoordinate,
  }) {
    final modo = uri.queryParameters['modo'];
    if (modo != 'foco') {
      ref.read(focusedMarketingCaseIdProvider.notifier).state = null;
    }
    final clienteId = uri.queryParameters['clienteId'];
    final clienteNome = uri.queryParameters['clienteNome'];
    final fazendaId = uri.queryParameters['fazendaId'];
    final fazendaNome = uri.queryParameters['fazendaNome'];
    final drawingId = uri.queryParameters['drawingId'];

    if ((modo == 'desenho' || modo == 'editar') && clienteId != null) {
      AppLogger.debug(
        'MAP-FIRST: recebido modo=$modo clienteId=$clienteId fazendaId=$fazendaId drawingId=$drawingId',
        tag: 'PrivateMap',
      );
      ref
          .read(drawingClientProvider.notifier)
          .setClienteAtivo(
            clienteId,
            clientName: clienteNome,
            farmId: fazendaId,
            farmName: fazendaNome,
          );
      setSheetState(
        const MapSheetState(type: MapSheetType.draw),
        'query_param_modo_desenho',
      );
      if (drawingId != null && drawingId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusDrawing(drawingId, edit: modo == 'editar');
        });
      }
      return;
    }

    if (modo == 'importar') {
      AppLogger.debug(
        'MAP-FIRST: recebido modo=importar clienteId=$clienteId fazendaId=$fazendaId',
        tag: 'PrivateMap',
      );
      if (clienteId != null) {
        ref
            .read(drawingClientProvider.notifier)
            .setClienteAtivo(
              clienteId,
              clientName: clienteNome,
              farmId: fazendaId,
              farmName: fazendaNome,
            );
      }
      setSheetState(
        const MapSheetState(type: MapSheetType.draw),
        'query_param_modo_importar',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(drawingControllerProvider).startImportMode();
      });
      return;
    }

    if (modo == 'visita' && clienteId != null) {
      AppLogger.debug(
        'MAP-FIRST: recebido modo=visita clienteId=$clienteId',
        tag: 'PrivateMap',
      );
      setSheetState(
        MapSheetState(
          type: MapSheetType.checkIn,
          preSelectedClienteId: clienteId,
        ),
        'query_param_modo_visita',
      );
      return;
    }

    if (modo == 'ocorrencia') {
      AppLogger.debug('MAP-FIRST: recebido modo=ocorrencia', tag: 'PrivateMap');
      armOccurrenceMode();
      return;
    }

    if (modo == 'foco') {
      final lat = double.tryParse(uri.queryParameters['lat'] ?? '');
      final lng = double.tryParse(uri.queryParameters['lng'] ?? '');
      final caseId = uri.queryParameters['caseId']?.trim();
      if (lat == null || lng == null) {
        AppLogger.warning(
          'MAP-FIRST: modo=foco sem lat/lng válidos',
          tag: 'PrivateMap',
        );
        return;
      }
      if (!lat.isFinite || !lng.isFinite) return;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return;
      if (lat == 0 && lng == 0) return;

      AppLogger.debug(
        'MAP-FIRST: recebido modo=foco lat=$lat lng=$lng caseId=$caseId',
        tag: 'PrivateMap',
      );
      ref.read(focusedMarketingCaseIdProvider.notifier).state =
          (caseId != null && caseId.isNotEmpty) ? caseId : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusCoordinate(LatLng(lat, lng));
      });
    }
  }
}
