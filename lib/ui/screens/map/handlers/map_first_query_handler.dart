import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/map/map_sheet_state.dart';
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
  }) {
    final modo = uri.queryParameters['modo'];
    final clienteId = uri.queryParameters['clienteId'];
    final drawingId = uri.queryParameters['drawingId'];

    if ((modo == 'desenho' || modo == 'editar') && clienteId != null) {
      AppLogger.debug(
        'MAP-FIRST: recebido modo=$modo clienteId=$clienteId drawingId=$drawingId',
        tag: 'PrivateMap',
      );
      ref.read(drawingClientProvider.notifier).setClienteAtivo(clienteId);
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
        'MAP-FIRST: recebido modo=importar clienteId=$clienteId',
        tag: 'PrivateMap',
      );
      if (clienteId != null) {
        ref.read(drawingClientProvider.notifier).setClienteAtivo(clienteId);
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
    }
  }
}
