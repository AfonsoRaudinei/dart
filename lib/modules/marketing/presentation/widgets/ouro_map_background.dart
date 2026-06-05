import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/plano_marketing.dart';
import '../../presentation/providers/marketing_providers.dart';
import '../../presentation/widgets/marketing_case_marker.dart';
import '../../presentation/widgets/marketing_case_sheet.dart';

/// Mapa de background isolado para a tela de login.
/// Exibe apenas pins OURO (visíveis sem autenticação).
/// Usa animação sutil de paralaxe/drift para criar movimento orgânico.
class OuroMapBackground extends ConsumerStatefulWidget {
  const OuroMapBackground({super.key});

  @override
  ConsumerState<OuroMapBackground> createState() => _OuroMapBackgroundState();
}

class _OuroMapBackgroundState extends ConsumerState<OuroMapBackground>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _driftController;
  late Animation<double> _driftAnimation;
  bool _isMapReady = false;

  // Centro do Brasil (fallback antes do GPS)
  static const LatLng _defaultCenter = LatLng(-15.7942, -47.8825);
  static const double _defaultZoom = 5.5;

  @override
  void initState() {
    super.initState();
    // Animação suave de drift (zoom in lento)
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    _driftAnimation = Tween<double>(
      begin: _defaultZoom,
      end: _defaultZoom + 1.2,
    ).animate(CurvedAnimation(parent: _driftController, curve: Curves.linear));

    _driftAnimation.addListener(_onDriftTick);
    _driftController.forward();
  }

  void _onDriftTick() {
    if (!_isMapReady) return;
    try {
      _mapController.move(_defaultCenter, _driftAnimation.value);
    } catch (error) {
      AppLogger.debug(
        'Drift ignorado antes do mapa ficar pronto: $error',
        tag: 'LoginMap',
      );
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(marketingCasesProvider);
    final ouros =
        casesAsync.valueOrNull
            ?.where((c) => c.visibilidade == PlanoMarketing.ouro)
            .toList() ??
        [];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
        minZoom: 4.0,
        maxZoom: 10.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none, // Mapa totalmente bloqueado
        ),
        onMapReady: () => setState(() => _isMapReady = true),
      ),
      children: [
        // Tiles do mapa (Carto Positron — mais suave para background)
        TileLayer(
          urlTemplate: MapConfig.cartoPositron,
          subdomains: MapConfig.cartoSubdomains,
          userAgentPackageName: MapConfig.userAgent,
          tileProvider: NetworkTileProvider(),
        ),

        // Pins Ouro
        if (ouros.isNotEmpty)
          MarkerLayer(
            markers: ouros.map((MarketingCase mCase) {
              return Marker(
                point: LatLng(mCase.lat, mCase.lng),
                width: 80,
                height: 80,
                alignment: Alignment.topCenter,
                child: MarketingCaseMarker(
                  marketingCase: mCase,
                  onTap: () => MarketingCaseSheet.show(context, mCase),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
