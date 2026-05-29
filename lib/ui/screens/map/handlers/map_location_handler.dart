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
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/dashboard/services/location_service.dart';

class MapLocationHandler {
  MapLocationHandler._();

  static StreamSubscription<LatLng>? _followSubscription;

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

  /// Centraliza o mapa na posição atual do usuário.
  /// Verifica [isMapReady] antes de operar no [mapController].
  static Future<void> centerOnUser({
    required WidgetRef ref,
    required BuildContext context,
    required MapController mapController,
    required bool isMapReady,
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
      mapController.move(position, 16.0);
    }
  }

  /// Inicia follow contínuo da câmera usando o stream GPS existente.
  static void startFollowing({
    required Stream<LatLng> locationStream,
    required MapController mapController,
    required bool isMapReady,
  }) {
    _followSubscription?.cancel();
    if (!isMapReady) return;

    _followSubscription = locationStream.listen(
      (position) {
        mapController.move(position, mapController.camera.zoom);
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  /// Cancela o follow contínuo da câmera.
  static void stopFollowing() {
    _followSubscription?.cancel();
    _followSubscription = null;
  }
}
