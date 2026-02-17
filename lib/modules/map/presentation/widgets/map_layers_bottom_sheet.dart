import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/map_models.dart';

class MapLayersBottomSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final LatLng currentCenter;
  final double currentZoom;

  const MapLayersBottomSheet({
    super.key,
    required this.scrollController,
    required this.currentCenter,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Estados
    final currentMode = ref.watch(activeLayerProvider);
    final showPins = ref.watch(showMarkersProvider);

    // 🔹 2. BLUR REAL DE FUNDO
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75), // Glass effect base
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1️⃣ HANDLE iOS + TÍTULO
              _buildHeader(context),

              // CONTEÚDO SCROLLÁVEL
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // 3️⃣ CONTAINER DOS 3 CARDS
                    _buildCardsRow(context, ref, currentMode),

                    const SizedBox(height: 24),

                    // 🔹 SEÇÃO SOBREPOSIÇÕES
                    const Divider(height: 1, color: Color(0xFFEBEBEB)),
                    const SizedBox(height: 16),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Sobreposições',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Toggle - Mostrar Pinos
                    _buildToggle(ref, showPins),

                    // Espaço extra inferior
                    const SizedBox(height: 40),
                    // SafeArea bottom padding
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Handle
        Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 16),
        // Título + Fechar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Camadas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF1D1D1F)),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCardsRow(
    BuildContext context,
    WidgetRef ref,
    LayerType currentMode,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 24) / 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 140,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCard(
              ref,
              mode: LayerType.standard,
              label: 'Padrão',
              isSelected: currentMode == LayerType.standard,
              width: cardWidth,
            ),
            _buildCard(
              ref,
              mode: LayerType.satellite,
              label: 'Satélite',
              isSelected: currentMode == LayerType.satellite,
              width: cardWidth,
            ),
            _buildCard(
              ref,
              mode: LayerType.terrain,
              label: 'Relevo',
              isSelected: currentMode == LayerType.terrain,
              width: cardWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    WidgetRef ref, {
    required LayerType mode,
    required String label,
    required bool isSelected,
    required double width,
  }) {
    final activeColor = const Color(0xFF4CAF50);
    final inactiveBorder = const Color(0xFFE0E0E0);
    final bgPreview = const Color(0xFFF5F5F5);

    return GestureDetector(
      onTap: () {
        // 🔹 3. HAPTIC FEEDBACK
        HapticFeedback.lightImpact();
        ref.read(activeLayerProvider.notifier).setLayer(mode);
      },
      child: Column(
        children: [
          // A. MINI PREVIEW REAL
          // 🔹 4. ANIMAÇÃO PREMIUM (Scale)
          AnimatedScale(
            scale: isSelected ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              width: width,
              height: 90,
              decoration: BoxDecoration(
                color: bgPreview,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? activeColor : inactiveBorder,
                  width: isSelected ? 3.0 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // 🔹 1. MINI MAP RENDER
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13), // 16 - 3 border
                    child: _MiniMapPreview(
                      mode: mode,
                      center: currentCenter,
                      zoom: 13, // Fixed zoom for context
                    ),
                  ),

                  // CHECK SELECTION
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: FadeTransition(
                        opacity: const AlwaysStoppedAnimation(1),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // B. LABEL
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? activeColor : const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(WidgetRef ref, bool showPins) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: const BoxDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mostrar Pinos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Switch.adaptive(
              value: showPins,
              activeColor: const Color(0xFF4CAF50),
              activeTrackColor: const Color(0xFF4CAF50),
              inactiveTrackColor: const Color(0xFFE0E0E0),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                ref.read(showMarkersProvider.notifier).toggle();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 5. PERFORMANCE: Stateless Isolated Mini Map
class _MiniMapPreview extends StatelessWidget {
  final LayerType mode;
  final LatLng center;
  final double zoom;

  const _MiniMapPreview({
    required this.mode,
    required this.center,
    required this.zoom,
  });

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

  @override
  Widget build(BuildContext context) {
    // 🔹 RepaintBoundary para isolar renderização pesada
    return RepaintBoundary(
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: _getLayerUrl(mode),
              userAgentPackageName: 'com.soloforte.app',
            ),
            // Sem markers, sem polígonos, apenas visual clean
          ],
        ),
      ),
    );
  }
}
