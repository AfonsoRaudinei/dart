// ADR-030 F5 — Classe extraída de private_map_screen.dart (B3)
// Gerencia permissão de localização, centralização e follow do mapa.
// Classe estática — mantém somente a assinatura do follow contínuo.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/permissions/location_permission_gate.dart';
import '../../../../core/permissions/permission_provider.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../../modules/dashboard/domain/user_location_fix.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/dashboard/services/location_service.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';

class MapLocationHandler {
  MapLocationHandler._();

  static StreamSubscription<UserLocationFix>? _followSubscription;

  /// Solicita permissão de localização e, se concedida, centraliza o mapa.
  static Future<void> requestPermission({
    required WidgetRef ref,
    required BuildContext context,
    required MapController mapController,
    required bool isMapReady,
  }) async {
    final permission = await ref.read(locationPermissionProvider.future);
    if (!context.mounted) return;

    if (permission == LocationPermission.denied) {
      final newPermission = await LocationPermissionGate.request();
      if (!context.mounted) return;

      await _handlePermissionResult(
        permission: newPermission,
        ref: ref,
        context: context,
        mapController: mapController,
        isMapReady: isMapReady,
      );
    } else {
      await _handlePermissionResult(
        permission: permission,
        ref: ref,
        context: context,
        mapController: mapController,
        isMapReady: isMapReady,
      );
    }
  }

  static Future<void> _handlePermissionResult({
    required LocationPermission permission,
    required WidgetRef ref,
    required BuildContext context,
    required MapController mapController,
    required bool isMapReady,
  }) async {
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await centerOnUser(
        ref: ref,
        context: context,
        mapController: mapController,
        isMapReady: isMapReady,
      );
    } else if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permissão de localização negada permanentemente. Ative nas configurações do dispositivo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static void showGPSRequiredMessage({
    required WidgetRef ref,
    required BuildContext context,
  }) {
    final state = ref.read(locationStateProvider);
    String message;

    switch (state) {
      case LocationState.permissionDenied:
        message =
            'GPS indisponível: permissão negada. Habilite nas configurações do app.';
        break;
      case LocationState.serviceDisabled:
        message =
            'GPS desligado. Ative o GPS nas configurações do dispositivo.';
        break;
      case LocationState.checking:
        message = 'Aguardando verificação do GPS...';
        break;
      default:
        message = 'GPS indisponível. Funções geográficas bloqueadas.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showGpsLowAccuracyMessage({
    required BuildContext context,
    required double accuracyMeters,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Precisão GPS insuficiente (±${accuracyMeters.round()}m). '
          'Aguarde sinal melhor ou vá para área aberta para fazer check-in.',
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Centraliza o mapa na posição atual do usuário.
  /// Verifica [isMapReady] antes de operar no [mapController].
  ///
  /// [animateTo] opcional: ease Apple-like no primeiro recenter.
  /// Follow contínuo continua usando move instantâneo.
  static Future<void> centerOnUser({
    required WidgetRef ref,
    required BuildContext context,
    required MapController mapController,
    required bool isMapReady,
    MapLocationMode locationMode = MapLocationMode.idle,
    void Function(LatLng dest, double zoom)? animateTo,
  }) async {
    // 🔒 Guard: Verificar se o mapa está pronto
    if (!isMapReady) return;

    final permission = await ref.read(locationPermissionProvider.future);
    if (!context.mounted) return;

    if (permission == LocationPermission.denied) {
      final newPermission = await LocationPermissionGate.request();
      if (!context.mounted) return;

      await _handlePermissionResult(
        permission: newPermission,
        ref: ref,
        context: context,
        mapController: mapController,
        isMapReady: isMapReady,
      );
      return;
    }

    // 🚫 Bloqueio: GPS obrigatório para centralizar
    final locationState = ref.read(locationStateProvider);
    if (locationState != LocationState.available) {
      await ref.read(locationStateProvider.notifier).init();
      if (!context.mounted) return;

      final retryState = ref.read(locationStateProvider);
      if (retryState != LocationState.available) {
        showGPSRequiredMessage(ref: ref, context: context);
        return;
      }
    }

    HapticFeedback.lightImpact();

    // Centralizar na posição atual (obtida do stream)
    final locationService = LocationService();
    final position = await locationService.getCurrentPosition();

    if (position != null && isMapReady && context.mounted) {
      // Recenter intencional: preferir ease; follow contínuo permanece instantâneo.
      if (animateTo != null && locationMode == MapLocationMode.idle) {
        animateTo(position.position, 16.0);
        return;
      }
      _applyCameraForFix(
        mapController: mapController,
        fix: position,
        zoom: 16.0,
        mode: locationMode,
      );
    }
  }

  /// Inicia follow contínuo da câmera usando o stream GPS existente.
  static void startFollowing({
    required MapLocationMode mode,
    required Stream<UserLocationFix> locationStream,
    required MapController mapController,
    required bool isMapReady,
  }) {
    _followSubscription?.cancel();
    if (!isMapReady) return;

    // Norte sempre para cima: following e northLocked zeraram a câmera.
    // O gesto de rotação está desabilitado no MapCanvas — sem isso o rumo
    // GNSS podia deixar o norte nas laterais sem caminho de volta.
    if (mode == MapLocationMode.following ||
        mode == MapLocationMode.northLocked) {
      mapController.rotate(0);
    }

    _followSubscription = locationStream.listen(
      (fix) {
        _applyCameraForFix(
          mapController: mapController,
          fix: fix,
          zoom: mapController.camera.zoom,
          mode: mode,
        );
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  static void _applyCameraForFix({
    required MapController mapController,
    required UserLocationFix fix,
    required double zoom,
    required MapLocationMode mode,
  }) {
    final rotation = _mapRotationForMode(mode: mode);

    if (rotation != null) {
      mapController.moveAndRotate(fix.position, zoom, rotation);
      return;
    }

    mapController.move(fix.position, zoom);
  }

  /// Retorna rotação alvo do mapa (0° = norte para cima) ou `null` para
  /// manter a atual.
  ///
  /// `following` e `northLocked` são sempre norte-acima. Course-up por rumo
  /// GNSS foi removido: `Position.heading` é rumo de deslocamento (não
  /// azimute de bússola) e, parado, entrega valores arbitrários — o mapa
  /// ficava com norte nas laterais e sem gesto de rotação para corrigir.
  @visibleForTesting
  static double? mapRotationForMode({
    required MapLocationMode mode,
  }) {
    return _mapRotationForMode(mode: mode);
  }

  static double? _mapRotationForMode({
    required MapLocationMode mode,
  }) {
    switch (mode) {
      case MapLocationMode.northLocked:
      case MapLocationMode.following:
        return 0;
      case MapLocationMode.idle:
        return null;
    }
  }

  /// Cancela o follow contínuo da câmera.
  static void stopFollowing() {
    _followSubscription?.cancel();
    _followSubscription = null;
  }
}
