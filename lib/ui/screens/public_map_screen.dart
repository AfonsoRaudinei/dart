import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../components/public_map/access_button.dart';
import '../components/public_map/public_publication_pins.dart';
import '../components/public_map/public_publication_preview.dart';
import '../components/public_map/error_overlay.dart';
import '../components/public_map/loading_overlay.dart';
import '../../modules/public/providers/public_location_provider.dart';
import '../../modules/public/providers/map_style_provider.dart';
import '../../modules/public/providers/public_publications_provider.dart';
import '../../modules/marketing/presentation/providers/marketing_providers.dart';
import '../../modules/marketing/domain/enums/plano_marketing.dart';
import '../../modules/marketing/presentation/widgets/marketing_case_marker.dart';
import '../../modules/marketing/presentation/widgets/marketing_case_sheet.dart';
import '../../core/config/map_config.dart';
import '../../core/permissions/permission_provider.dart';
import '../../core/permissions/location_permission_gate.dart';

class PublicMapScreen extends ConsumerStatefulWidget {
  const PublicMapScreen({super.key});

  @override
  ConsumerState<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends ConsumerState<PublicMapScreen> {
  final MapController _mapController = MapController();
  static const double _defaultZoom = 13.0;
  static const double _userLocationZoom = 16.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    final permission = await ref.read(locationPermissionProvider.future);
    if (permission == LocationPermission.denied) {
      final newPermission = await LocationPermissionGate.request();
      _handlePermissionResult(newPermission);
    } else {
      _handlePermissionResult(permission);
    }
  }

  Future<void> _handlePermissionResult(LocationPermission permission) async {
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      await ref.read(publicLocationNotifierProvider.notifier).requestLocation();
      _onLocationTap();
    } else if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização negada permanentemente. Ative nas configurações do dispositivo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < 18.0) {
      final newZoom = (currentZoom + 1).clamp(3.0, 18.0);
      _mapController.move(_mapController.camera.center, newZoom);
    }
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > 3.0) {
      final newZoom = (currentZoom - 1).clamp(3.0, 18.0);
      _mapController.move(_mapController.camera.center, newZoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onLocationTap() async {
    final permission = await ref.read(locationPermissionProvider.future);
    if (permission == LocationPermission.denied) {
      final newPermission = await LocationPermissionGate.request();
      _handlePermissionResult(newPermission);
      return;
    }

    final locationState = ref.read(publicLocationNotifierProvider);

    if (locationState.status == PublicLocationStatus.available &&
        locationState.position != null) {
      // Animação suave ao centralizar
      _mapController.move(locationState.position!, _userLocationZoom);
    } else {
      await ref.read(publicLocationNotifierProvider.notifier).requestLocation();
      final updatedState = ref.read(publicLocationNotifierProvider);
      if (updatedState.status == PublicLocationStatus.available && updatedState.position != null) {
        _mapController.move(updatedState.position!, _userLocationZoom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(publicLocationNotifierProvider);
    final mapStyle = ref.watch(publicMapStyleProvider);
    final publicationsAsync = ref.watch(publicPublicationsProvider);

    return Scaffold(
      // 🛡 IPA-123: background branco — visível antes dos tiles do FlutterMap
      // carregarem durante a janela isInitializing=true (debounce 300ms).
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Mapa como fundo
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-23.5505, -46.6333), // SP Default
              initialZoom: _defaultZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              // TileLayer com estilo iOS
              TileLayer(
                urlTemplate: mapStyle.tileUrl,
                userAgentPackageName: MapConfig.userAgent,
                subdomains: mapStyle.subdomains ?? const [],
                additionalOptions: const {
                  'attribution': '', // Atribuição será no rodapé
                },
                // Fallback para OpenStreetMap em caso de erro
                fallbackUrl: MapConfig.fallbackStyle,
              ),

              // Pins de publicações públicas com animação fade in
              publicationsAsync.when(
                data: (publications) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: MarkerLayer(
                    key: ValueKey('markers_${publications.length}'),
                    markers: PublicPublicationPins.createMarkers(
                      publications,
                      (publication) =>
                          showPublicPublicationPreview(context, publication),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, _) => const SizedBox.shrink(),
              ),

              // Pinos de Marketing (Apenas Ouro na tela deslogada)
              if (ref.watch(marketingCasesProvider).hasValue)
                MarkerLayer(
                  markers: ref
                      .watch(marketingCasesProvider)
                      .value!
                      .where(
                        (mCase) => mCase.visibilidade == PlanoMarketing.ouro,
                      )
                      .map((mCase) {
                        return Marker(
                          point: LatLng(mCase.lat, mCase.lng),
                          width: 100,
                          height: 100,
                          alignment: Alignment.center,
                          child: MarketingCaseMarker(
                            marketingCase: mCase,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              MarketingCaseSheet.show(context, mCase);
                            },
                          ),
                        );
                      })
                      .toList(),
                ),

              // Ponto azul da localização do usuário - iOS style
              if (locationState.status == PublicLocationStatus.available &&
                  locationState.position != null)
                CircleLayer(
                  circles: [
                    // Círculo externo (halo suave)
                    CircleMarker(
                      point: locationState.position!,
                      radius: 35,
                      useRadiusInMeter: true,
                      color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                      borderColor: const Color(
                        0xFF007AFF,
                      ).withValues(alpha: 0.2),
                      borderStrokeWidth: 1,
                    ),
                    // Círculo interno (ponto azul sólido)
                    CircleMarker(
                      point: locationState.position!,
                      radius: 10,
                      useRadiusInMeter: false,
                      color: const Color(0xFF007AFF),
                      borderColor: Colors.white,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
            ],
          ),

          // Marca d'água SoloForte no topo esquerdo
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: const _SoloForteWatermark(),
          ),

          // Pill vertical: zoom + localização
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PillButton(icon: Icons.add, onTap: _zoomIn),
                        const _PillDivider(),
                        _PillButton(icon: Icons.remove, onTap: _zoomOut),
                        const _PillDivider(),
                        _PillButton(
                          icon: Icons.my_location_rounded,
                          onTap: _onLocationTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Overlay de erro para publicações
          if (publicationsAsync.hasError)
            PublicMapErrorOverlay(
              message: 'Não foi possível carregar as publicações',
              icon: Icons.cloud_off_outlined,
              onRetry: () => ref.invalidate(publicPublicationsProvider),
            ),

          // Overlay de erro para localização
          if (locationState.status == PublicLocationStatus.error)
            PublicMapErrorOverlay(
              message: 'Não foi possível obter sua localização',
              icon: Icons.location_off_outlined,
              onRetry: () => ref
                  .read(publicLocationNotifierProvider.notifier)
                  .requestLocation(),
            ),

          // Loading overlay para publicações
          if (publicationsAsync.isLoading) const PublicationsLoadingOverlay(),

          // Botão "Acessar SoloForte" centralizado na parte inferior
          const Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(child: AccessSoloForteButton()),
          ),
        ],
      ),
    );
  }
}

/// Marca d'água de sistema, flutuante sobre o mapa.
class _SoloForteWatermark extends StatelessWidget {
  const _SoloForteWatermark();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.eco_outlined,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'SoloForte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão individual dentro do pill
class _PillButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 50,
        child: Icon(
          icon,
          size: 22,
          color: Colors.black.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}

/// Divisor entre botões do pill
class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.black.withValues(alpha: 0.12),
    );
  }
}
