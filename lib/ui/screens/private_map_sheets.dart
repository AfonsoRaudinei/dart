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

  // 🔧 MODAL: delegate para MapSheetController.openSheet — ADR-031 F4
  void _openSheetAsModal(BuildContext context, MapSheetState state) {
    MapSheetController.openSheet(
      context,
      ref,
      state,
      _armOccurrenceMode,
      _setSheetState,
      _setModalOpen,
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

  // 🔧 delegate para MapSheetController.toggleDrawMode — ADR-031 F4
  void _toggleDrawMode() {
    MapSheetController.toggleDrawMode(context, ref, _setSheetState);
  }
}
