import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:soloforte_app/ui/components/map/map_sheets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/map_state.dart';
import '../../core/domain/map_models.dart';

import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../../core/utils/map_logger.dart';
import '../../core/utils/debouncer.dart';

class PrivateMapScreen extends ConsumerStatefulWidget {
  const PrivateMapScreen({super.key});

  @override
  ConsumerState<PrivateMapScreen> createState() => _PrivateMapScreenState();
}

class _PrivateMapScreenState extends ConsumerState<PrivateMapScreen> {
  final MapController _mapController = MapController();
  final _mapEventDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );

  bool _hasInitialFocused = false;
  bool _isDrawMode = false;
  bool _isCheckedIn = false;

  @override
  void dispose() {
    _mapEventDebouncer.dispose();
    super.dispose();
  }

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => sheet,
      ),
    );
  }

  String _getLayerUrl(LayerType type) {
    switch (type) {
      case LayerType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case LayerType.terrain:
        return 'https://b.tile.opentopomap.org/{z}/{x}/{y}.png';
      case LayerType.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _handleAutoZoom(List<Publication>? pubs) {
    if (_hasInitialFocused || pubs == null || pubs.isEmpty) return;

    // "Contexto Inicial Inteligente" - First Load Only
    _hasInitialFocused = true;

    try {
      final points = pubs.map((e) => e.location).toList();
      if (points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(points);
        // Slightly delay to allow map to render size
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        });
      }
    } catch (_) {}
  }

  void _toggleDrawMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDrawMode = !_isDrawMode;
    });

    if (_isDrawMode) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Modo de Desenho Ativo'),
          backgroundColor: SoloForteColors.greenDark,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Protection against accidental exit
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Edição cancelada'),
          action: SnackBarAction(
            label: 'DESFAZER',
            textColor: SoloForteColors.greenIOS,
            onPressed: () {
              setState(() => _isDrawMode = true);
            },
          ),
        ),
      );
    }
  }

  void _toggleCheckIn() {
    HapticFeedback.lightImpact();

    if (_isCheckedIn) {
      // Ending Check-in (Protection)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Encerrar Check-in?'),
          action: SnackBarAction(
            label: 'CONFIRMAR',
            textColor: SoloForteColors.greenIOS,
            onPressed: () {
              setState(() => _isCheckedIn = false);
            },
          ),
        ),
      );
    } else {
      // Starting
      setState(() => _isCheckedIn = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Check-in iniciado. Bom trabalho!'),
          backgroundColor: SoloForteColors.greenDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    final activeLayer = ref.watch(activeLayerProvider);
    final showMarkers = ref.watch(showMarkersProvider);
    final publications = ref.watch(publicationsDataProvider);

    // Auto-focus Logic
    ref.listen(publicationsDataProvider, (prev, next) {
      if (next.hasValue && !_hasInitialFocused) {
        _handleAutoZoom(next.value);
      }
    });

    List<Marker> markers = [];

    try {
      if (showMarkers && publications.hasValue) {
        final pubs = publications.value!;
        markers.addAll(
          pubs.map(
            (pub) => Marker(
              point: pub.location,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: SoloForteColors.greenIOS,
                size: 40,
              ),
            ),
          ),
        );

        // Fallback for initial load if listen missed it (race condition)
        if (!_hasInitialFocused) {
          _handleAutoZoom(pubs);
        }
      }
    } catch (e, s) {
      MapLogger.logError('Failed to generate markers', s);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stopwatch.stop();
      MapLogger.logRenderTime(stopwatch.elapsedMilliseconds);
      MapLogger.logMarkerCount(markers.length);
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(-23.5505, -46.6333),
            initialZoom: 14.0,
            minZoom: 4.0,
            maxZoom: 19.0,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                _mapEventDebouncer.run(() {
                  MapLogger.logEvent(
                    'Pan/Zoom: Center=${pos.center.latitude.toStringAsFixed(4)},${pos.center.longitude.toStringAsFixed(4)} Zoom=${pos.zoom.toStringAsFixed(1)}',
                  );
                  bool isClusteringActive = pos.zoom < 15;
                  MapLogger.logEvent('Clustering Active: $isClusteringActive');
                });
              }
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: _getLayerUrl(activeLayer),
              userAgentPackageName: 'com.soloforte.app',
            ),
            if (markers.isNotEmpty)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 120,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: markers,
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: SoloForteColors.greenIOS,
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),

        // 1. Header with Data Trust (Top Left)
        Positioned(
          top: 60,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: SoloForteColors.white.withValues(alpha: 0.95),
              borderRadius: SoloRadius.radiusMd,
              boxShadow: [SoloShadows.shadowSm],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: SoloForteColors.greenIOS,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SoloForte Privado',
                      style: SoloTextStyles.headingMedium.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Atualizado agora', // Data Trust State
                    style: SoloTextStyles.label.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Action Column (Right Side)
        Positioned(
          top: 100,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapActionButton(
                icon: Icons.edit,
                label: 'Talhão',
                isActive: _isDrawMode,
                onTap: _toggleDrawMode,
              ),
              const SizedBox(height: 12),

              _MapActionButton(
                icon: Icons.my_location,
                label: 'Eu',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _mapController.move(const LatLng(-23.5505, -46.6333), 16.0);
                },
              ),
              const SizedBox(height: 12),

              _MapActionButton(
                icon: Icons.layers,
                label: 'Camadas',
                onTap: () => _showSheet(context, const LayersSheet()),
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Ocorrências',
                onTap: () => _showSheet(context, const OccurrencesSheet()),
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: Icons.article_outlined,
                label: 'Publicações',
                onTap: () => _showSheet(context, const PublicationsSheet()),
              ),
            ],
          ),
        ),

        // 3. Check-in Context Button (Bottom Right)
        Positioned(
          bottom: 120,
          right: 20,
          child: GestureDetector(
            onTap: _toggleCheckIn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isCheckedIn
                    ? SoloForteColors.greenIOS
                    : SoloForteColors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: SoloShadows.shadowButton,
                border: Border.all(color: SoloForteColors.greenIOS, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCheckedIn ? Icons.check : Icons.sync_alt,
                    color: _isCheckedIn
                        ? Colors.white
                        : SoloForteColors.greenIOS,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCheckedIn ? 'Em Campo' : 'Check-in',
                    style: SoloTextStyles.body.copyWith(
                      color: _isCheckedIn
                          ? Colors.white
                          : SoloForteColors.greenIOS,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? SoloForteColors.greenIOS
                  : SoloForteColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? SoloForteColors.greenIOS.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : SoloForteColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: SoloTextStyles.label.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
