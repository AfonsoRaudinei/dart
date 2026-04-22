import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/permissions/location_permission_gate.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/models/gps_walk_session.dart';
import '../../domain/services/geo_calculator_service.dart';
import '../../domain/services/gps_tracking_service.dart';
import '../providers/drawing_provider.dart';

/// Notifier que gerencia o ciclo de vida completo de uma sessão GPS Walk.
///
/// ### Responsabilidades
/// - Gerenciar [GpsWalkStatus]: idle → measuring → paused → finished
/// - Delegar operações de GPS stream ao [DrawingController]
/// - Sincronizar pontos coletados e recalcular métricas em tempo real
/// - Gerenciar o toggle auto/manual de coleta de pontos
///
/// ### AutoDispose
/// O provider é `autoDispose`: sem vazar memória após conclusão ou cancelamento.
///
/// ### Contrato com DrawingController
/// - Apenas ADICIONA comportamento; não altera métodos existentes
/// - Delega: startGpsTracking(), pauseGpsTracking(), resumeGpsTracking(),
///   finalizeGpsTracking(), cancelOperation(), addManualGpsPoint()
///
/// ### Padrão Riverpod
/// Segue o padrão de Notifier manual (sem code-gen) consistente com
/// os demais providers do módulo drawing.
class GpsWalkNotifier extends AutoDisposeNotifier<GpsWalkSession?> {
  @override
  GpsWalkSession? build() => null;

  // ─── Helpers privados ─────────────────────────────────────────────────────

  /// Acesso ao DrawingController via ref.read (evita race conditions).
  get _dc => ref.read(drawingControllerProvider);

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Ativa o modo GPS Walk em estado IDLE.
  ///
  /// GPS stream NÃO inicia aqui. O usuário deve pressionar "Começar a medir".
  /// Chamado quando o usuário seleciona "GPS (caminhar)" no DrawingToolSelector.
  void activate() {
    state = GpsWalkSession.initial();
    AppLogger.debug('GPS Walk: ativado (idle)', tag: 'GpsWalkNotifier');
  }

  /// Inicia a medição GPS (idle → measuring).
  ///
  /// Solicita permissão via [DrawingController.startGpsTracking] (que já gerencia
  /// a permissão e o stream). Transiciona o status para [GpsWalkStatus.measuring].
  Future<void> startMeasuring() async {
    if (state?.status != GpsWalkStatus.idle) return;

    state = state!.copyWith(
      status: GpsWalkStatus.measuring,
      startedAt: DateTime.now(),
    );

    await _dc.startGpsTracking();
    AppLogger.debug('GPS Walk: medição iniciada', tag: 'GpsWalkNotifier');
  }

  /// Pausa a coleta automática (measuring → paused).
  ///
  /// Pontos já coletados são preservados.
  void pause() {
    if (state?.status != GpsWalkStatus.measuring) return;
    state = state!.copyWith(status: GpsWalkStatus.paused);
    _dc.pauseGpsTracking();
    AppLogger.debug('GPS Walk: pausado', tag: 'GpsWalkNotifier');
  }

  /// Retoma a coleta automática (paused → measuring).
  void resume() {
    if (state?.status != GpsWalkStatus.paused) return;
    state = state!.copyWith(status: GpsWalkStatus.measuring);
    _dc.resumeGpsTracking();
    AppLogger.debug('GPS Walk: retomado', tag: 'GpsWalkNotifier');
  }

  /// Alterna entre modo automático (GPS stream) e manual (toque para adicionar).
  ///
  /// Ao desativar o auto, a coleta GPS é pausada automaticamente.
  /// Ao reativar o auto durante medição, o stream é retomado.
  void toggleAutoMode() {
    if (state == null) return;
    final newAuto = !state!.isAutoMode;
    state = state!.copyWith(isAutoMode: newAuto);

    if (state!.status == GpsWalkStatus.measuring) {
      if (!newAuto) {
        _dc.pauseGpsTracking(); // Auto OFF → pausar stream
      } else {
        _dc.resumeGpsTracking(); // Auto ON → retomar stream
      }
    }
    AppLogger.debug(
      'GPS Walk: modo auto = $newAuto',
      tag: 'GpsWalkNotifier',
    );
  }

  /// Captura a posição GPS atual e adiciona manualmente ao polígono.
  ///
  /// Usado no modo manual ([isAutoMode] = false).
  /// Verifica permissão antes de solicitar posição.
  Future<void> addManualPoint() async {
    if (state == null) return;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await LocationPermissionGate.request();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        AppLogger.warning(
          'GPS Walk: permissão negada para ponto manual',
          tag: 'GpsWalkNotifier',
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _dc.addManualGpsPoint(LatLng(pos.latitude, pos.longitude));
      AppLogger.debug('GPS Walk: ponto manual adicionado', tag: 'GpsWalkNotifier');
    } catch (e) {
      AppLogger.warning(
        'GPS Walk: erro ao obter posição manual',
        tag: 'GpsWalkNotifier',
        error: e,
      );
    }
  }

  /// Sincroniza pontos coletados do DrawingController e recalcula métricas.
  ///
  /// Chamado via `ref.listen` no widget ao detectar mudança em gpsVertices.
  /// Computa perímetro e área usando [GeoCalculatorService].
  void syncFromController(List<LatLng> points) {
    if (state == null) return;
    state = state!.copyWith(
      points: List.unmodifiable(points),
      perimeterMeters: GeoCalculatorService.calculatePerimeterMeters(points),
      areaSquareMeters: GeoCalculatorService.calculateAreaSquareMeters(points),
    );
  }

  /// Finaliza a sessão e envia a geometria ao DrawingController.
  ///
  /// Requer mínimo de [kGpsMinVertices] pontos.
  /// Após finalizar, o DrawingController transiciona para reviewing
  /// e o formulário de confirmação é exibido.
  void finish() {
    final points = _dc.gpsVertices;
    if (points.length < kGpsMinVertices) {
      AppLogger.warning(
        'GPS Walk: finish ignorado — menos de $kGpsMinVertices pontos',
        tag: 'GpsWalkNotifier',
      );
      return;
    }
    _dc.finalizeGpsTracking();
    state = state!.copyWith(
      status: GpsWalkStatus.finished,
      finishedAt: DateTime.now(),
    );
    AppLogger.debug('GPS Walk: concluído', tag: 'GpsWalkNotifier');
  }

  /// Cancela a sessão sem persistir dados.
  ///
  /// Chama cancelOperation() no DrawingController e descarta o estado.
  void cancel() {
    _dc.cancelOperation();
    state = null;
    AppLogger.debug('GPS Walk: cancelado', tag: 'GpsWalkNotifier');
  }
}
