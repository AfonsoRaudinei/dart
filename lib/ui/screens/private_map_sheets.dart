// ignore_for_file: use_build_context_synchronously
part of 'private_map_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// Extensão de _PrivateMapScreenState: Lógica de sheets e modais
// ════════════════════════════════════════════════════════════════════════════
// Extraído para manter private_map_screen.dart abaixo de 900 linhas.
// (Sprint 7 — Bounded Context Hygiene)
//
// Contém:

//   · _handleMapLongPress           — modal NovoCaseSheet + DraftSavedSheet
//   · _openSheetAsModal             — wrapper DraggableScrollableSheet
//   · _buildSheetContent            — switch de conteúdo por MapSheetType
//   · _buildActiveVisitContent      — UI de visita ativa no checkIn sheet
//   · _toggleDrawMode               — alternar modo desenho

extension _PrivateMapSheets on _PrivateMapScreenState {

  // ── _handleMapLongPress ───────────────────────────────────────────────────

  void _handleMapLongPress(TapPosition tapPos, LatLng latLng) {
    if (!mounted) return;

    // Abre NovoCaseSheet sempre — verificação de plano ocorre no onPublicar
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: SoloForteSheetTokens.sheetBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: NovoCaseSheet(
                lat: latLng.latitude,
                lng: latLng.longitude,
                onClose: () => Navigator.of(context).pop(),
                onPublicar: (newCase) async {
                  // Verifica plano APÓS preenchimento do formulário
                  final plano = ref.read(planoAtivoProvider).valueOrNull;

                  if (plano == null || plano.expirado) {
                    // Sem plano → salva como rascunho
                    try {
                      await ref
                          .read(marketingCasesProvider.notifier)
                          .saveAsDraft(newCase);

                      if (!mounted) return;

                      // Fecha o NovoCaseSheet
                      Navigator.of(context).pop();

                      // Exibe DraftSavedSheet e captura decisão do usuário.
                      final goToPlanos = await DraftSavedSheet.show(context);

                      if (!mounted) return;
                      if (goToPlanos == true) {
                        context.go('/planos');
                      }
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.of(context).pop(); // Fecha sheet mesmo em erro
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar rascunho: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  // Com plano → verifica limite de cases publicados
                  final cases =
                      ref.read(marketingCasesProvider).valueOrNull ?? [];
                  final casesPublicados = cases
                      .where(
                        (c) =>
                            c.status.toValue() == 'published' &&
                            c.ativo &&
                            c.deletadoEm == null,
                      )
                      .length;

                  if (casesPublicados >= plano.limiteCases) {
                    // Limite atingido
                    if (!mounted) return;
                    Navigator.of(context).pop(); // Fecha NovoCaseSheet
                    PlanoBlockSheet.show(
                      context,
                      motivo: 'limite_atingido',
                      planoLabel: plano.plano.label,
                    );
                    return;
                  }

                  // Publica normalmente
                  Navigator.of(context).pop(); // Fecha o sheet

                  final saved = await ref
                      .read(marketingCasesProvider.notifier)
                      .publishCase(newCase);

                  if (!mounted) return;
                  if (saved != null) {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Case publicado com sucesso! 📈'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF34C759),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sem conexão — case salvo localmente e será sincronizado.',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── _openSheetAsModal ─────────────────────────────────────────────────────

  // 🔧 MODAL: Abre os tipos publications/occurrences/checkIn/layers como modal nativo
  // Observação: o fluxo de Drawing NÃO usa showModalBottomSheet.
  // Drawing é renderizado via MapBottomSheet no Stack (MapSheetType.draw).
  void _openSheetAsModal(BuildContext context, MapSheetState state) {
    if (_isModalOpen) return;
    if (!mounted) return;
    _setModalOpen(true);
    final gen = ++_modalGeneration;

    // Bug 1: checkIn precisa de mais altura inicial e máxima para exibir
    // 4 dropdowns + botão sem corte. Outros tipos mantêm valores anteriores.
    final isCheckIn = state.type == MapSheetType.checkIn;
    final initialSize = isCheckIn ? 0.6 : 0.5;
    final maxSize = isCheckIn ? 0.92 : 0.9;
    final snapSizesList = isCheckIn ? [0.6, 0.92] : [0.5, 0.9];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      enableDrag: true,
      isDismissible: true,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: initialSize,
        minChildSize: 0.3,
        maxChildSize: maxSize,
        expand: false,
        snap: true,
        snapSizes: snapSizesList,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(child: _buildSheetContent(state, scrollController)),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted && gen == _modalGeneration) {
        _setModalOpen(false);
        final currentState = ref.read(mapSheetStateProvider);
        if (currentState?.type == state.type) {
          _setSheetState(null, 'Modal: whenComplete dismiss');
        }
      }
    });
  }

  // ── _buildSheetContent ────────────────────────────────────────────────────

  // 🔧 MODAL: Conteúdo específico por tipo (recebe scrollController do DraggableScrollableSheet)
  Widget _buildSheetContent(
    MapSheetState state,
    ScrollController scrollController,
  ) {
    switch (state.type) {
      case MapSheetType.layers:
        return SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          child: LayersSheet(onClose: () => Navigator.of(context).pop()),
        );
      case MapSheetType.occurrences:
        if (state.isCreatingOccurrence && _pendingOccurrenceLocation != null) {
          final lat = _pendingOccurrenceLocation!.latitude;
          final lng = _pendingOccurrenceLocation!.longitude;
          return OccurrenceCreationSheet(
            latitude: lat,
            longitude: lng,
            scrollController: scrollController,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: (data) {
              ref.read(occurrenceControllerProvider).createOccurrence(
                type: data.type,
                description: data.description,
                clientId: data.clientId,
                photoPath: data.photoPath,
                lat: lat,
                long: lng,
                category: data.category,
                status: 'draft',
                cultivar: data.cultivar,
                dataPlantio: data.dataPlantio,
                estadioFenologico: data.estadioFenologico,
                tipoOcorrencia: data.tipoOcorrencia,
                amostraSolo: data.amostraSolo,
                recomendacoes: data.recomendacoes,
                metricasJson: data.metricasJson,
                nutrientesJson: data.nutrientesJson,
                categoriasJson: data.categoriasJson,
                notasCategoriasJson: data.notasCategoriasJson,
                fotosCategoriasJson: data.fotosCategoriasJson,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ocorrência registrada com sucesso!'),
                  backgroundColor: PremiumTokens.brandGreen,
                ),
              );
              Navigator.of(context).pop();
            },
          );
        }
        return OccurrenceListSheet(
          scrollController: scrollController,
          showHandle: false,
          showDecoration: false,
          mapBounds: null,
          onClose: () => Navigator.of(context).pop(),
          onOccurrenceTap: (occurrence) {
            AppLogger.debug(
              'Ocorrência tocada: ${occurrence.id}',
              tag: 'MapSheet',
            );
          },
          onRequestNewOccurrence: () {
            Navigator.of(context).pop();
            // FIX 1: Armar modo seleção de ponto em vez de abrir sheet diretamente
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _armOccurrenceMode();
            });
          },
        );
      case MapSheetType.checkIn:
        return Consumer(
          builder: (ctx, widgetRef, _) {
            // ⚡ Sprint 8: .select() para rebuild só quando status muda
            final isActive = widgetRef.watch(
              visitControllerProvider.select(
                (v) => v.valueOrNull?.status == 'active',
              ),
            );
            if (isActive) {
              return _buildActiveVisitContent(widgetRef);
            }
            return VisitSheet(
              preSelectedClienteId: state.preSelectedClienteId,
              // Bug 1: scrollController conecta DraggableScrollableSheet ao
              // SingleChildScrollView interno para expansão correta via drag.
              scrollController: scrollController,
              onConfirm: (clientId, areaId, activity) {
                widgetRef
                    .read(visitControllerProvider.notifier)
                    .startSession(clientId, areaId, activity, 0.0, 0.0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visita iniciada. Bom trabalho!'),
                    backgroundColor: PremiumTokens.brandGreenDark,
                  ),
                );
                Navigator.of(context).pop();
              },
            );
          },
        );
      case MapSheetType.draw:
        // Nunca deve chegar aqui — draw permanece no Stack
        return const SizedBox.shrink();
    }
  }

  // ── _buildActiveVisitContent ──────────────────────────────────────────────

  // 🔧 MODAL: UI de visita ativa no checkIn sheet
  Widget _buildActiveVisitContent(WidgetRef widgetRef) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(SFIcons.checkCircle, size: 64, color: PremiumTokens.brandGreen),
          const SizedBox(height: 16),
          Text(
            'Visita em Andamento',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              // ✅ FIX Causa A: ler sessão da mesma fonte que o card.
              // visitControllerProvider.endSession() acessa state.value
              // (SQLite offline-first) — sem depender de agendaProvider.
              // Após encerrar: state = null → card desaparece reativamente.
              try {
                await widgetRef
                    .read(visitControllerProvider.notifier)
                    .endSession();
                if (mounted) {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visita encerrada com sucesso.'),
                      backgroundColor: PremiumTokens.brandGreenDark,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao encerrar visita: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTokens.alertError,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Encerrar Visita'),
          ),
        ],
      ),
    );
  }

  // ── _finishDrawing ────────────────────────────────────────────────────────

  // 🔧 Helper to finish drawing
  Future<void> _finishDrawing() async {
    final controller = ref.read(drawingControllerProvider);

    // 🔒 GUARD: Evitar re-entrância ou chamadas duplicadas (Fix Duplication)
    // Só processar se estiver no estado de desenho
    if (controller.currentState != DrawingState.drawing) {
      return;
    }

    // Verificar se há pontos suficientes
    if (controller.liveGeometry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos 3 pontos para criar um polígono'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔧 CHANGE STATE: Mudar para modo de revisão
    controller.completeDrawing();

    // 🔒 VALIDATION: Garantir que a transição ocorreu com sucesso
    if (controller.currentState != DrawingState.reviewing) {
      return;
    }
  }

  // ── _toggleDrawMode ───────────────────────────────────────────────────────

  void _toggleDrawMode() {
    HapticFeedback.mediumImpact();
    final controller = ref.read(drawingControllerProvider);
    // Reuso intencional do mapSheetStateProvider como estado de abertura
    // do DrawingSheet (toggle do ícone de desenho no mapa).
    // Não há drawingSheetOpenProvider separado.
    final currentSheet = ref.read(mapSheetStateProvider);

    // Toggle explícito: se draw já está aberto, fecha.
    if (currentSheet?.type == MapSheetType.draw) {
      final wasDrawing = controller.currentState != DrawingState.idle;
      // Mantém comportamento anterior: cancelar operação ativa ao fechar.
      controller.cancelOperation();
      _setSheetState(null, 'ToggleDrawMode: Closing draw sheet');

      if (wasDrawing) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desenho cancelado'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Abrir draw quando estiver fechado.
    _setSheetState(
      const MapSheetState(type: MapSheetType.draw),
      'ToggleDrawMode: Opening draw sheet',
    );
  }
}
