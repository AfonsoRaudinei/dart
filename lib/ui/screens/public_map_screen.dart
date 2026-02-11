import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../components/public_map/access_button.dart';
import '../components/public_map/location_button.dart';
import '../components/public_map/zoom_controls.dart';
import '../components/public_map/public_publication_pins.dart';
import '../components/public_map/public_publication_preview.dart';
import '../components/public_map/error_overlay.dart';
import '../components/public_map/loading_overlay.dart';
import '../../modules/public/providers/public_location_provider.dart';
import '../../modules/public/providers/map_style_provider.dart';
import '../../modules/public/providers/public_publications_provider.dart';
import '../../core/config/map_config.dart';

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
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnUserLocation() {
    final locationState = ref.read(publicLocationNotifierProvider);

    if (locationState.status == PublicLocationStatus.available &&
        locationState.position != null) {
      // Animação suave ao centralizar
      _mapController.move(
        locationState.position!,
        _userLocationZoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(publicLocationNotifierProvider);
    final mapStyle = ref.watch(publicMapStyleProvider);
    final publicationsAsync = ref.watch(publicPublicationsProvider);

    return Scaffold(
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
                      borderColor: const Color(0xFF007AFF).withValues(alpha: 0.2),
                      borderStrokeWidth: 1,
                    ),
                    // Círculo interno (ponto azul sólido)
                    CircleMarker(
                      point: locationState.position!,
                      radius: 10,
                      useRadiusInMeter: false,
                      color: const Color(0xFF007AFF),
                      borderColor: SoloForteColors.white,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
            ],
          ),

          // Badge "Mapa Público" no topo esquerdo
          Positioned(
            top: 60,
            left: 20,
            child: Semantics(
              label: 'Mapa Público - Explore publicações da comunidade',
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: SoloForteColors.white.withValues(alpha: 0.9),
                borderRadius: SoloRadius.radiusMd,
                boxShadow: [SoloShadows.shadowSm],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 20, color: SoloForteColors.greenIOS),
                  const SizedBox(width: 8),
                  Text(
                    'Mapa Público',
                    style: SoloTextStyles.headingMedium.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),            ),          ),

          // Botão de localização no topo direito
          Positioned(
            top: 60,
            right: 20,
            child: LocationButton(onLocationObtained: _centerOnUserLocation),
          ),

          // Controles de zoom no canto inferior direito
          Positioned(
            bottom: 120,
            right: 20,
            child: ZoomControls(
              mapController: _mapController,
              minZoom: 3.0,
              maxZoom: 18.0,
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
              onRetry: () =>
                  ref.read(publicLocationNotifierProvider.notifier).requestLocation(),
            ),

          // Loading overlay para publicações
          if (publicationsAsync.isLoading)
            const PublicationsLoadingOverlay(),

          // Botão "Acessar SoloForte" centralizado na parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(child: const AccessSoloForteButton()),
          ),
        ],
      ),
    );
  }
}
