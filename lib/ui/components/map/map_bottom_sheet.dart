import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/soloforte_theme.dart';
import 'package:latlong2/latlong.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
// Navegação movida para FloatingDockWidget
import 'tabs/map_tab_content.dart';
import 'map_sheets.dart';
import '../../../modules/drawing/presentation/widgets/drawing_sheet.dart';
import '../../../modules/drawing/presentation/widgets/drawing_disabled_widget.dart';
import '../../../modules/drawing/presentation/controllers/drawing_controller.dart';
import '../../../modules/visitas/presentation/widgets/visit_sheet.dart';
import '../../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../../modules/dashboard/controllers/location_controller.dart';
import '../../../core/feature_flags/feature_flag_providers.dart';
import '../../../core/feature_flags/feature_flag_resolver.dart';
import '../../../core/feature_flags/feature_flag_analytics.dart';
import '../../../../modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart';
import 'map_occurrence_sheet.dart';

/// Bottom Sheet estilo iOS "Buscar" com 3 detents
/// Compacto → Médio → Expandido
enum SheetDetent { compact, medium, expanded }

class MapBottomSheet extends ConsumerStatefulWidget {
  final DrawingController drawingController;
  final VoidCallback onLocationRequested;
  final VoidCallback onOccurrenceArmed;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;
  final LatLng? creationLocation; // Coordenadas para iniciar criação imediata

  const MapBottomSheet({
    super.key,
    required this.drawingController,
    required this.onLocationRequested,
    required this.onOccurrenceArmed,
    required this.selectedTabIndex,
    required this.onTabChanged,
    this.creationLocation,
  });

  @override
  ConsumerState<MapBottomSheet> createState() => _MapBottomSheetState();
}

class _MapBottomSheetState extends ConsumerState<MapBottomSheet>
    with SingleTickerProviderStateMixin {
  SheetDetent _currentDetent = SheetDetent.compact;
  int _mapSubActionIndex = -1; // Sub-ação dentro da tab Mapa (-1 = nenhum)

  late AnimationController _heightController;
  late Animation<double> _heightAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _heightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightAnimation =
        Tween<double>(begin: _getSheetHeight(), end: _getSheetHeight()).animate(
          CurvedAnimation(parent: _heightController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTabIndex != oldWidget.selectedTabIndex) {
      // Mapear tabs de atalho para sub-ações diretas
      switch (widget.selectedTabIndex) {
        case 1: // Publicações
          _mapSubActionIndex = 2;
          break;
        case 3: // Check-in
          _mapSubActionIndex = 3;
          break;
        // Case 2 (Ocorrências) é tratado nativamente pelo _buildTabContent ou via creationLocation
      }

      // Se sheet estiver compacto, expandir para médio ao trocar tab
      if (_currentDetent == SheetDetent.compact) {
        _animateToDetent(SheetDetent.medium);
      }
    }

    // Detectar solicitação de criação de ocorrência (Armed Mode)
    if (widget.creationLocation != null &&
        widget.creationLocation != oldWidget.creationLocation) {
      // Forçar expansão e mudança para tab de ocorrências se não estiver
      if (_currentDetent != SheetDetent.expanded) {
        _animateToDetent(SheetDetent.expanded);
      }
      // O estado de criação é gerenciado reativamente no build via widget.creationLocation
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

  void _handleMapSubAction(int subIndex) async {
    HapticFeedback.lightImpact();

    // GPS check para ações que requerem localização
    final locationController = ref.read(locationStateProvider);
    final needsGPS = subIndex == 0 || subIndex == 3; // Desenhar ou Check-in

    if (needsGPS && !_isGPSAvailable(locationController)) {
      _showGPSRequiredMessage();
      return;
    }

    setState(() {
      _mapSubActionIndex = subIndex;
    });
    _animateToDetent(SheetDetent.expanded);
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
        // Flick para baixo → retrair
        if (_currentDetent == SheetDetent.expanded) {
          _animateToDetent(SheetDetent.medium);
        } else if (_currentDetent == SheetDetent.medium) {
          _animateToDetent(SheetDetent.compact);
        }
      }
      return;
    }

    // Snap baseado em percentual: 35% / 65%
    final compactHeight = _getDetentHeight(SheetDetent.compact);
    final mediumHeight = _getDetentHeight(SheetDetent.medium);
    final expandedHeight = _getDetentHeight(SheetDetent.expanded);

    // Calcular em qual "zona" está
    if (currentHeight < (compactHeight + mediumHeight) * 0.5) {
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

  bool _isGPSAvailable(dynamic state) {
    return state.toString().contains('available');
  }

  void _showGPSRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'GPS indisponível. Habilite para usar esta função.',
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double _getSheetHeight() {
    switch (_currentDetent) {
      case SheetDetent.compact:
        return 90; // Só tab bar (iOS style)
      case SheetDetent.medium:
        return 350; // Tab bar + conteúdo médio
      case SheetDetent.expanded:
        return MediaQuery.of(context).size.height * 0.75; // 75% da tela
    }
  }

  Widget _buildTabContent() {
    Widget content;

    switch (widget.selectedTabIndex) {
      case 0: // Mapa (principal)
        if (_mapSubActionIndex == -1) {
          if (_currentDetent == SheetDetent.expanded) {
            content = MapTabContent(
              onDrawingTap: () => _handleMapSubAction(0),
              onLayersTap: () => _handleMapSubAction(1),
              onPublicationsTap: () => _handleMapSubAction(2),
              onCheckInTap: () => _handleMapSubAction(3),
            );
          } else {
            content = _buildQuickActionsBar();
          }
        } else {
          content = _buildMapSubActionContent();
        }
        break;
      case 1: // Publicações (atalho direto)
        content = _buildMapSubActionContent();
        break;
      case 2: // Ocorrências (Consolidado)
        return _buildOccurrencesContent();
      case 3: // Check-in (atalho direto)
        content = _buildMapSubActionContent();
        break;
      default:
        content = const SizedBox.shrink();
    }

    // Envolver em SingleChildScrollView com ScrollController
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: content,
    );
  }

  Widget _buildMapSubActionContent() {
    switch (_mapSubActionIndex) {
      case 0: // Desenhar
        return FutureBuilder<bool>(
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
        );
      case 1: // Camadas
        return const LayersSheet();
      case 2: // Publicações
        return const PublicacoesSheet();
      case 3: // Check-in
        return _buildCheckInContent();
      default:
        return const SizedBox.shrink();
    }
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
                setState(() {
                  _mapSubActionIndex = -1;
                  _currentDetent = SheetDetent.compact;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visita encerrada com sucesso.'),
                  ),
                );
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

        setState(() {
          _mapSubActionIndex = -1;
          _currentDetent = SheetDetent.compact;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visita iniciada. Bom trabalho!'),
              backgroundColor: SoloForteColors.greenDark,
            ),
          );
        }
      },
    );
  }

  // 🛡 CONSOLIDAÇÃO OCORRÊNCIAS
  // Estado local para alternar entre Lista e Criação dentro da tab
  bool _isCreatingOccurrence = false;

  Widget _buildOccurrencesContent() {
    // Se recebemos um local de criação via props (Armed Mode), priorizamos a criação
    final isCreationMode =
        _isCreatingOccurrence || widget.creationLocation != null;

    if (isCreationMode) {
      // Modo Criação (MapOccurrenceSheet)
      // Se widget.creationLocation for nulo mas _isCreatingOccurrence for true,
      // precisamos de uma posição. Fallback para 0,0 ou Center?
      // O fluxo correto é: Botão Add -> Pega Localização -> Define state.
      // Se _isCreatingOccurrence for true sem location, algo errado.
      // Assumimos que quem setou _isCreatingOccurrence garantiu location (ex: botão de add na lista)

      final lat = widget.creationLocation?.latitude ?? 0;
      final lng = widget.creationLocation?.longitude ?? 0;

      return MapOccurrenceSheet(
        latitude: lat,
        longitude: lng,
        scrollController: ScrollController(), // Sheet interno gerencia scroll?
        onCancel: () {
          // Voltar para lista
          setState(() => _isCreatingOccurrence = false);
          // Se veio via prop creationLocation, o pai (PrivateMapScreen) precisa limpar.
          // Como não temos callback de "limpar intent", o usuário terá que navegar via tabs ou fechar.
          // Ideal: Resetar intent no pai. Por enquanto, switch to List visualmente.

          // Se foi via Armed Mode (creationLocation != null), user provavelmente quer cancelar tudo.
          if (widget.creationLocation != null) {
            // Efeito colateral: Se o pai não limpar o creationLocation, o rebuild traria de volta.
            // Para resolver, invocamos o onTabChanged para a mesma tab (noop) ou
            // assumimos que o pai limpa o creationLocation quando processado?
            // "Hack": Mudar para tab Mapa (0) fecha o fluxo de ocorrências.
            widget.onTabChanged(0);
          }
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

          // Sucesso -> Voltar para lista ou fechar?
          // Voltar para lista parece natural
          setState(() => _isCreatingOccurrence = false);
          if (widget.creationLocation != null)
            widget.onTabChanged(0); // Fecha se veio do mapa
        },
      );
    }

    // Modo Lista (OccurrenceListSheet)
    return OccurrenceListSheet(
      mapBounds:
          null, // Opcional: passar bounds se quisermos filtrar pelo viewport atual
      onClose: () => widget.onTabChanged(0), // Fechar volta para Mapa
      onOccurrenceTap: (occurrence) {
        // Navegar para detalhes?
        _handleMapSubAction(0); // Exemplo placeholder
      },
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
                              key: ValueKey(widget.selectedTabIndex),
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

  /// Barra de ações rápidas (estados compacto/médio)
  Widget _buildQuickActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickActionButton(
            icon: SFIcons.edit,
            label: 'Desenhar',
            onTap: () => _handleMapSubAction(0),
          ),
          _QuickActionButton(
            icon: SFIcons.layers,
            label: 'Camadas',
            onTap: () => _handleMapSubAction(1),
          ),
          _QuickActionButton(
            icon: SFIcons.article,
            label: 'Publicar',
            onTap: () => _handleMapSubAction(2),
          ),
          _QuickActionButton(
            icon: SFIcons.checkCircle,
            label: 'Check',
            onTap: () => _handleMapSubAction(3),
          ),
          _QuickActionButton(
            icon: SFIcons.warning,
            label: 'Ocorrência',
            onTap: () {
              HapticFeedback.lightImpact();
              // Solicitar ao pai (PrivateMapScreen) para armar o modo de ocorrência
              widget.onOccurrenceArmed();
            },
          ),
        ],
      ),
    );
  }
}

/// Botão de ação rápida (somente ícone)
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Colors.black.withValues(alpha: 0.6);

    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
      },
      onTapUp: (_) {
        _scaleController.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () {
        _scaleController.reverse();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(widget.icon, size: 28, color: iconColor),
        ),
      ),
    );
  }
}
