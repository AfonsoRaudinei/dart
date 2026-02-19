import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/soloforte_theme.dart';
import 'package:latlong2/latlong.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'map_sheets.dart';
import '../../../modules/drawing/presentation/widgets/drawing_sheet.dart';
import '../../../modules/drawing/presentation/widgets/drawing_disabled_widget.dart';
import '../../../modules/drawing/presentation/controllers/drawing_controller.dart';
import '../../../modules/visitas/presentation/widgets/visit_sheet.dart';
import '../../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../../core/feature_flags/feature_flag_providers.dart';
import '../../../core/feature_flags/feature_flag_resolver.dart';
import '../../../core/feature_flags/feature_flag_analytics.dart';
import '../../../../modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart';
import 'map_occurrence_sheet.dart';
import 'map_sheet_state.dart'; // 🛡 REFATORAÇÃO: Modelo compartilhado
import '../../../core/utils/app_logger.dart';

/// Bottom Sheet estilo iOS "Buscar" com 3 detents
/// Compacto → Médio → Expandido
enum SheetDetent { closed, compact, medium, expanded }

class MapBottomSheet extends ConsumerStatefulWidget {
  final DrawingController drawingController;
  final VoidCallback onLocationRequested;
  final VoidCallback onOccurrenceArmed;
  final VoidCallback onClose;
  final MapSheetState state; // 🛡 REFATORAÇÃO: Estado explícito do pai
  final Function(MapSheetState)
  onStateChange; // 🛡 REFATORAÇÃO: Callback de mudança
  final LatLng? creationLocation;

  const MapBottomSheet({
    super.key,
    required this.drawingController,
    required this.onLocationRequested,
    required this.onOccurrenceArmed,
    required this.onClose,
    required this.state,
    required this.onStateChange,
    this.creationLocation,
  });

  @override
  ConsumerState<MapBottomSheet> createState() => _MapBottomSheetState();
}

class _MapBottomSheetState extends ConsumerState<MapBottomSheet>
    with SingleTickerProviderStateMixin {
  // 🛡 APENAS ESTADOS EFÉMEROS DE UI (animação e drag)
  SheetDetent _currentDetent = SheetDetent.compact;

  late AnimationController _heightController;
  late Animation<double> _heightAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AppLogger.debug('MapBottomSheet INIT | type=${widget.state.type}', tag: 'MapSheet');

    // 🔧 FIX: Apenas inicializar estados de UI (animação)
    _currentDetent = SheetDetent.compact;

    _heightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final initialHeight = 90.0; // Sempre começa compacto
    _heightAnimation = AlwaysStoppedAnimation(initialHeight);
  }

  @override
  void dispose() {
    AppLogger.debug('MapBottomSheet DISPOSE', tag: 'MapSheet');
    _heightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🛡 REFATORAÇÃO: Apenas reagir a mudanças de tipo para animar detent
    if (widget.state.type != oldWidget.state.type) {
      // Expandir automaticamente quando mudar de tipo
      if (_currentDetent == SheetDetent.compact) {
        _animateToDetent(SheetDetent.medium);
      }
    }

    // Expandir se solicitou criação de ocorrência
    if (widget.creationLocation != null &&
        widget.creationLocation != oldWidget.creationLocation) {
      if (_currentDetent != SheetDetent.expanded) {
        _animateToDetent(SheetDetent.expanded);
      }
    }
  }

  void _animateToDetent(SheetDetent targetDetent) {
    if (_currentDetent == targetDetent) return;

    final startHeight = _getSheetHeight();
    setState(() => _currentDetent = targetDetent);
    final endHeight = _getSheetHeight();

    _heightAnimation = Tween<double>(begin: startHeight, end: endHeight)
        .animate(
          CurvedAnimation(parent: _heightController, curve: Curves.easeOut),
        );

    _heightController.forward(from: 0);
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    final isScrollAtTop =
        !_scrollController.hasClients ||
        _scrollController.position.pixels <= 1.0; // Tolerância para bouncing

    // Só permitir drag se:
    // 1. Sheet estiver compacto (sempre pode arrastar)
    // 2. Scroll estiver no topo (permite arrastar para baixo)
    if (_currentDetent == SheetDetent.compact || isScrollAtTop) {
      setState(() {
        final delta = details.primaryDelta ?? 0;
        final currentHeight = _heightAnimation.value;
        final newHeight = (currentHeight - delta).clamp(
          _getDetentHeight(SheetDetent.compact),
          _getDetentHeight(SheetDetent.expanded),
        );

        _heightAnimation = AlwaysStoppedAnimation(newHeight);
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    // Preparar para drag (se necessário adicionar lógica futura)
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final currentHeight = _heightAnimation.value;

    // Flick detection: velocidade alta determina direção (threshold 800)
    if (velocity.abs() > 800) {
      if (velocity < 0) {
        // Flick para cima → expandir
        if (_currentDetent == SheetDetent.compact) {
          _animateToDetent(SheetDetent.medium);
        } else if (_currentDetent == SheetDetent.medium) {
          _animateToDetent(SheetDetent.expanded);
        }
      } else {
        // Flick para baixo → retrair ou fechar
        if (_currentDetent == SheetDetent.expanded) {
          _animateToDetent(SheetDetent.medium);
        } else if (_currentDetent == SheetDetent.medium) {
          _animateToDetent(SheetDetent.compact);
        } else if (_currentDetent == SheetDetent.compact) {
          // 🔹 FECHAMENTO REAL: Flick down no compact (ETAPA 3)
          widget.onClose();
        }
      }
      return;
    }

    // Snap baseado em percentual: 35% / 65%
    final compactHeight = _getDetentHeight(SheetDetent.compact);
    final mediumHeight = _getDetentHeight(SheetDetent.medium);
    final expandedHeight = _getDetentHeight(SheetDetent.expanded);
    final closeThreshold = compactHeight * 0.7; // 70% do compact para fechar

    // Calcular em qual "zona" está
    if (currentHeight < closeThreshold) {
      // 🔹 FECHAMENTO REAL: Drag abaixo do threshold (ETAPA 3)
      widget.onClose();
    } else if (currentHeight < (compactHeight + mediumHeight) * 0.5) {
      _animateToDetent(SheetDetent.compact);
    } else if (currentHeight < (mediumHeight + expandedHeight) * 0.5) {
      _animateToDetent(SheetDetent.medium);
    } else {
      _animateToDetent(SheetDetent.expanded);
    }
  }

  double _getDetentHeight(SheetDetent detent) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safeAreaBottom = mediaQuery.padding.bottom;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    switch (detent) {
      case SheetDetent.closed:
        return 0;
      case SheetDetent.compact:
        return 90;
      case SheetDetent.medium:
        return 350;
      case SheetDetent.expanded:
        // 75% da tela - safe area - teclado
        final maxHeight = screenHeight * 0.75;
        final availableHeight = screenHeight - keyboardHeight - safeAreaBottom;
        return maxHeight.clamp(350, availableHeight);
    }
  }

  double _getSheetHeight() {
    switch (_currentDetent) {
      case SheetDetent.closed:
        return 0;
      case SheetDetent.compact:
        return 90; // Só tab bar (iOS style)
      case SheetDetent.medium:
        return 350; // Tab bar + conteúdo médio
      case SheetDetent.expanded:
        return MediaQuery.of(context).size.height * 0.75; // 75% da tela
    }
  }

  Widget _buildTabContent() {
    // 🛡 REFATORAÇÃO: Switch explícito baseado em MapSheetType (determinístico)
    switch (widget.state.type) {
      case MapSheetType.draw:
        return _buildDraw();
      case MapSheetType.layers:
        return _buildLayers();
      case MapSheetType.publications:
        return _buildPublications();
      case MapSheetType.occurrences:
        return widget.state.isCreatingOccurrence
            ? _buildOccurrenceForm()
            : _buildOccurrenceList();
      case MapSheetType.checkIn:
        return _buildCheckIn();
    }
  }

  Widget _buildDraw() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: FutureBuilder<bool>(
        future: _checkDrawingFeatureFlag(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return snapshot.data!
              ? DrawingSheet(controller: widget.drawingController)
              : const DrawingDisabledWidget();
        },
      ),
    );
  }

  Widget _buildLayers() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: LayersSheet(onClose: widget.onClose),
    );
  }

  Widget _buildPublications() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: PublicacoesSheet(onClose: widget.onClose),
    );
  }

  Widget _buildCheckIn() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: _buildCheckInContent(),
    );
  }

  Widget _buildCheckInContent() {
    final visitState = ref.watch(visitControllerProvider);
    final isActive = visitState.value?.status == 'active';

    if (isActive) {
      // Já está em visita - mostrar status
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              SFIcons.checkCircle,
              size: 64,
              color: SoloForteColors.greenIOS,
            ),
            const SizedBox(height: 16),
            Text('Visita em Andamento', style: SoloTextStyles.headingMedium),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.read(visitControllerProvider.notifier).endSession();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visita encerrada com sucesso.'),
                  ),
                );
                // 🔹 FECHAMENTO REAL: Encerrar visita fecha o sheet (ETAPA 5)
                widget.onClose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Encerrar Visita'),
            ),
          ],
        ),
      );
    }

    // Iniciar visita
    return VisitSheet(
      onConfirm: (clientId, areaId, activity) {
        // TODO: Obter posição real do GPS
        ref
            .read(visitControllerProvider.notifier)
            .startSession(
              clientId,
              areaId,
              activity,
              0.0, // Será preenchido com posição real
              0.0,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visita iniciada. Bom trabalho!'),
              backgroundColor: SoloForteColors.greenDark,
            ),
          );
        }
        // 🔹 FECHAMENTO REAL: Iniciar visita fecha o sheet (ETAPA 5)
        widget.onClose();
      },
    );
  }

  // 🛡 REFATORAÇÃO: Renderização de ocorrências (lista vs formulário)
  Widget _buildOccurrenceList() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: OccurrenceListSheet(
        mapBounds: null,
        onClose: () => widget.onClose(),
        onOccurrenceTap: (occurrence) {
          AppLogger.debug('Ocorrência tocada: ${occurrence.id}', tag: 'MapSheet');
        },
        onRequestNewOccurrence: () {
          // 🆕 Armar modo de ocorrência e fechar sheet
          widget.onOccurrenceArmed();
          // Não fecha o sheet, apenas instrui o usuário
        },
      ),
    );
  }

  Widget _buildOccurrenceForm() {
    final lat = widget.creationLocation?.latitude ?? 0;
    final lng = widget.creationLocation?.longitude ?? 0;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: MapOccurrenceSheet(
        latitude: lat,
        longitude: lng,
        scrollController: ScrollController(),
        onCancel: () {
          // 🛡 REFATORAÇÃO: Voltar para lista
          widget.onStateChange(
            const MapSheetState(
              type: MapSheetType.occurrences,
              isCreatingOccurrence: false,
            ),
          );
        },
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

          // Fechar o sheet após salvar
          widget.onClose();
        },
      ),
    );
  }

  Future<bool> _checkDrawingFeatureFlag() async {
    try {
      const user = FeatureFlagUser(
        userId: 'dev-user-001',
        role: 'consultor',
        appVersion: '1.1.0',
      );

      final isEnabled = await ref.read(isDrawingEnabledProvider(user).future);

      FeatureFlagAnalytics.trackDrawingAccess(
        userId: user.userId,
        userRole: user.role,
        wasEnabled: isEnabled,
      );

      return isEnabled;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('MapBottomSheet BUILD | type=${widget.state.type}', tag: 'MapSheet');
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleVerticalDrag,
      onVerticalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) {
          return SizedBox(
            height: _heightAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(SoloRadius.lg), // 24px
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withOpacity(0.92), // Adaptativo
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(SoloRadius.lg), // 24px
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        offset: const Offset(0, -4),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle (alça) - área de drag expandida
                      GestureDetector(
                        onTap: _handleHandleTap,
                        child: Container(
                          padding: const EdgeInsets.only(
                            top: 14,
                            bottom: 20,
                          ), // Hit area + margin
                          child: Center(
                            child: Container(
                              width: 36, // Mais largo
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.2), // Dinâmico
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Conteúdo da tab selecionada com cross-fade
                      if (_currentDetent != SheetDetent.compact)
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey(widget.state.type),
                              child: _buildTabContent(),
                            ),
                          ),
                        ),

                      // Navegação agora no FloatingDockWidget externo
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleHandleTap() {
    HapticFeedback.lightImpact();
    // Alternar entre detents ao tocar no handle
    if (_currentDetent == SheetDetent.compact) {
      _animateToDetent(SheetDetent.medium);
    } else if (_currentDetent == SheetDetent.medium) {
      _animateToDetent(SheetDetent.expanded);
    } else {
      _animateToDetent(SheetDetent.compact);
    }
  }
}
