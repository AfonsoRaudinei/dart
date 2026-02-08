import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:soloforte_app/ui/components/map/map_sheets.dart';
import 'package:soloforte_app/ui/components/map/map_occurrence_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/map_state.dart';
import '../../core/domain/map_models.dart';

import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../../core/utils/map_logger.dart';
import '../../core/utils/debouncer.dart';
import '../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../modules/dashboard/pages/map/drawing/drawing_sheet.dart';
import '../../modules/dashboard/pages/map/drawing/drawing_controller.dart';
import '../../modules/dashboard/controllers/location_controller.dart';
import '../../modules/dashboard/domain/location_state.dart';
import '../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../modules/visitas/presentation/widgets/visit_sheet.dart';
import '../../modules/visitas/presentation/controllers/geofence_controller.dart';
import '../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../modules/consultoria/occurrences/domain/occurrence.dart' as occ;
import '../components/map/occurrence_pins.dart';

class PrivateMapScreen extends ConsumerStatefulWidget {
  const PrivateMapScreen({super.key});

  @override
  ConsumerState<PrivateMapScreen> createState() => _PrivateMapScreenState();
}

// Enum para rastrear o modo armado
enum ArmedMode { none, occurrences }

class _PrivateMapScreenState extends ConsumerState<PrivateMapScreen> {
  final MapController _mapController = MapController();
  final DrawingController _drawingController =
      DrawingController(); // Local Drawing Controller
  final _mapEventDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );

  bool _hasInitialFocused = false;
  // bool _isDrawMode = false; // Removed legacy mode
  // bool _isCheckedIn = false; // Replaced by VisitController
  String? _activeSheetName;
  late LocationController _locationController;
  ArmedMode _armedMode = ArmedMode.none; // Estado do modo armado

  @override
  void initState() {
    super.initState();
    _locationController = LocationController(ref);
    // Inicializar GPS ao carregar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationController.init();
      ref.read(geofenceControllerProvider); // Start Geofence Monitoring
    });
  }

  @override
  void dispose() {
    _mapEventDebouncer.dispose();
    _drawingController.dispose();
    super.dispose();
  }

  void _showSheet(BuildContext context, Widget sheet, String name) async {
    setState(() => _activeSheetName = name);
    await showModalBottomSheet(
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
    if (mounted) {
      setState(() => _activeSheetName = null);
    }
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

  void _openDrawingMode() {
    // 🚫 Bloqueio: GPS obrigatório para desenhar
    if (!_locationController.isAvailable) {
      _showGPSRequiredMessage();
      return;
    }

    HapticFeedback.lightImpact();
    // Open Drawing Sheet
    _showSheet(
      context,
      DrawingSheet(controller: _drawingController),
      'drawing',
    );
  }

  void _toggleOccurrenceMode() {
    // 🚫 Bloqueio: GPS obrigatório para ocorrências
    if (!_locationController.isAvailable) {
      _showGPSRequiredMessage();
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      if (_armedMode == ArmedMode.occurrences) {
        // Desarmar modo (toggle off)
        _armedMode = ArmedMode.none;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      } else {
        // Armar modo (toggle on)
        _armedMode = ArmedMode.occurrences;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📍 Toque no mapa para registrar a ocorrência'),
            backgroundColor: SoloForteColors.greenIOS,
            duration: const Duration(seconds: 30),
            action: SnackBarAction(
              label: 'CANCELAR',
              textColor: Colors.white,
              onPressed: () {
                setState(() => _armedMode = ArmedMode.none);
              },
            ),
          ),
        );
      }
    });
  }

  void _toggleCheckIn() async {
    // 🚫 Bloqueio: GPS obrigatório para check-in
    if (!_locationController.isAvailable) {
      _showGPSRequiredMessage();
      return;
    }

    HapticFeedback.lightImpact();

    final visitState = ref.read(visitControllerProvider);
    final isActive = visitState.value?.status == 'active';

    if (isActive) {
      // Ending Check-in (Protection)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Encerrar Visita em Campo?'),
          action: SnackBarAction(
            label: 'ENCERRAR',
            textColor: Colors.redAccent,
            onPressed: () {
              ref.read(visitControllerProvider.notifier).endSession();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Visita encerrada com sucesso.')),
              );
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // Starting - Show Visit Sheet
      // Need location first
      final position = await _locationController.getCurrentPosition();
      if (position == null) {
        _showGPSRequiredMessage();
        return;
      }

      if (!mounted) return;

      _showSheet(
        context,
        VisitSheet(
          onConfirm: (clientId, areaId, activity) {
            ref
                .read(visitControllerProvider.notifier)
                .startSession(
                  clientId,
                  areaId,
                  activity,
                  position.latitude,
                  position.longitude,
                );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Visita iniciada. Bom trabalho!'),
                backgroundColor: SoloForteColors.greenDark,
              ),
            );
          },
        ),
        'visit_sheet',
      );
    }
  }

  void _showGPSRequiredMessage() {
    final state = _locationController.currentState;
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

  void _centerOnUser() {
    // 🚫 Bloqueio: GPS obrigatório para centralizar
    if (!_locationController.isAvailable) {
      _showGPSRequiredMessage();
      return;
    }

    HapticFeedback.lightImpact();
    // Centralizar na posição real do usuário
    _locationController.getCurrentPosition().then((position) {
      if (position != null) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          16.0,
        );
      }
    });
  }

  void _openOccurrenceSheet(double lat, double lng) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Reduzir um pouco para não cobrir tudo de cara
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        snap: true,
        builder: (_, controller) => MapOccurrenceSheet(
          scrollController: controller,
          latitude: lat,
          longitude: lng,
          onConfirm: (category, urgency, description) {
            ref
                .read(occurrenceControllerProvider)
                .createOccurrence(
                  type: urgency,
                  description: description,
                  lat: lat,
                  long: lng,
                  category: category,
                  status: 'draft',
                );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ocorrência registrada com sucesso!'),
                backgroundColor: SoloForteColors.greenIOS,
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleOccurrencePinTap(occ.Occurrence occurrence) {
    HapticFeedback.lightImpact();
    // Implement what happens when an occurrence pin is tapped
    // For example, show a detailed sheet or dialog for the occurrence
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ocorrência: ${occurrence.description}'),
        backgroundColor: SoloForteColors.greenIOS,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    final activeLayer = ref.watch(activeLayerProvider);
    final showMarkers = ref.watch(showMarkersProvider);
    final publications = ref.watch(publicationsDataProvider);
    final mapFields = ref.watch(mapFieldsProvider);
    final selectedTalhaoId = ref.watch(selectedTalhaoIdProvider);
    final locationState = ref.watch(locationStateProvider);
    final visitState = ref.watch(visitControllerProvider);
    final isCheckedIn = visitState.value?.status == 'active';

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
            onTap: (tapPos, point) {
              // 🎯 Prioridade 1: Verificar modo armado de ocorrências
              if (_armedMode == ArmedMode.occurrences) {
                final lat = point.latitude;
                final lng = point.longitude;

                // Desarmar imediatamente para evitar múltiplos taps
                setState(() => _armedMode = ArmedMode.none);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                // Abrir sheet de criação de ocorrência com coordenadas
                _openOccurrenceSheet(lat, lng);
                return; // Não processar lógica de talhão
              }

              // 🎯 Comportamento normal: Seleção de talhão
              final fields = mapFields.valueOrNull ?? [];
              bool hit = false;

              for (final field in fields) {
                if (field.geometry == null) continue;
                // Lazy parse for hit test (optimization: cache parsed polygons if needed)
                // Here purely for hit detection
                final polygonPoints = TalhaoMapAdapter.toPolygon(field).points;

                if (TalhaoMapAdapter.isPointInside(point, polygonPoints)) {
                  ref.read(selectedTalhaoIdProvider.notifier).state = field.id;
                  hit = true;
                  HapticFeedback.selectionClick();

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Talhão: ${field.name}'),
                      backgroundColor: SoloForteColors.greenIOS,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  break; // Stop on first hit
                }
              }

              if (!hit) {
                // Deselect if tapping empty space
                if (selectedTalhaoId != null) {
                  ref.read(selectedTalhaoIdProvider.notifier).state = null;
                  HapticFeedback.lightImpact();
                }
              }
            },
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
            if (mapFields.hasValue)
              PolygonLayer(
                polygons: mapFields.value!.map((t) {
                  return TalhaoMapAdapter.toPolygon(
                    t,
                    isSelected: t.id == selectedTalhaoId,
                  );
                }).toList(),
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
            // Layer de pins de ocorrências
            if (ref.watch(occurrencesListProvider).hasValue)
              MarkerLayer(
                markers: OccurrencePinGenerator.generatePins(
                  occurrences: ref.watch(occurrencesListProvider).value!,
                  currentZoom: _mapController.camera.zoom,
                  onPinTap: _handleOccurrencePinTap,
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
                const SizedBox(height: 8),
                // GPS Status Indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      locationState == LocationState.available
                          ? Icons.gps_fixed
                          : Icons.gps_off,
                      size: 12,
                      color: locationState == LocationState.available
                          ? SoloForteColors.greenIOS
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getGPSStatusText(locationState),
                      style: SoloTextStyles.label.copyWith(
                        fontSize: 9,
                        color: locationState == LocationState.available
                            ? SoloForteColors.greenIOS
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
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
                label: 'Desenhar',
                isActive: _activeSheetName == 'drawing',
                onTap: _openDrawingMode,
              ),
              const SizedBox(height: 12),

              _MapActionButton(
                icon: Icons.my_location,
                label: 'Eu',
                onTap: _centerOnUser,
              ),
              const SizedBox(height: 12),

              _MapActionButton(
                icon: Icons.layers,
                label: 'Camadas',
                isActive: _activeSheetName == 'layers',
                onTap: () => _showSheet(context, const LayersSheet(), 'layers'),
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Ocorrências',
                isActive: _armedMode == ArmedMode.occurrences,
                onTap: _toggleOccurrenceMode, // ✅ Spec: Clique arma modo
              ),
              const SizedBox(height: 12),
              _MapActionButton(
                icon: Icons.article_outlined,
                label: 'Publicações',
                isActive: _activeSheetName == 'publications',
                onTap: () => _showSheet(
                  context,
                  const PublicationsSheet(),
                  'publications',
                ),
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
            child: _buildCheckInStartButton(
              isCheckedIn: isCheckedIn,
              label: isCheckedIn ? 'Em Campo' : 'Check-in',
              color: isCheckedIn
                  ? SoloForteColors.greenIOS
                  : SoloForteColors.white,
              textColor: isCheckedIn ? Colors.white : SoloForteColors.greenIOS,
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget to avoid rebuilding entire map for button
  Widget _buildCheckInStartButton({
    required bool isCheckedIn,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: SoloShadows.shadowButton,
        border: Border.all(color: SoloForteColors.greenIOS, width: 2),
      ),
      child: Row(
        children: [
          Icon(isCheckedIn ? Icons.check : Icons.sync_alt, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: SoloTextStyles.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getGPSStatusText(LocationState state) {
    switch (state) {
      case LocationState.available:
        return 'GPS OK';
      case LocationState.permissionDenied:
        return 'GPS: Sem permissão';
      case LocationState.serviceDisabled:
        return 'GPS: Desligado';
      case LocationState.checking:
        return 'GPS: Verificando...';
    }
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
