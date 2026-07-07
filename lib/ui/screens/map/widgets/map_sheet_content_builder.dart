import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../../../modules/dashboard/services/location_service.dart';
import '../../../../modules/map/presentation/widgets/visit_sheet.dart';
import '../../../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../../../ui/components/map/map_sheet_state.dart';
import '../../../../ui/components/map/map_layers_sheet.dart';
import 'active_visit_sheet.dart';

/// Constrói o widget de conteúdo correto para cada [MapSheetType].
///
/// Extraído de `_PrivateMapSheets._buildSheetContent` — ADR-031 F3.
/// Função pura (sem estado próprio) — recebe todos os dados por parâmetro.
/// O switch aqui é o ponto de adição futura para [MapSheetType.clima]
/// (radar de chuva — usa climaRadarEnabledProvider / ADR-043).
Widget buildSheetContent(
  BuildContext context,
  WidgetRef ref,
  MapSheetState state,
  ScrollController scrollController,
  VoidCallback onArmOccurrenceMode,
) {
  switch (state.type) {
    case MapSheetType.layers:
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: LayersSheet(onClose: () => Navigator.of(context).pop()),
            ),
          );
        },
      );
    // R-2: MapSheetType.occurrences NUNCA chega a este builder em produção.
    // O guard em _setSheetState (private_map_screen.dart) redireciona occurrences
    // para o MapBottomSheet no Stack — nunca para sheet modal.
    // Manter este case ativo seria armadilha de double-save no OccurrenceController.
    // Caminho ativo: MapBuildOrchestrator → MapBottomSheet → _buildOccurrenceForm/_buildOccurrenceList
    case MapSheetType.occurrences:
      // Código morto intencional: se chegar aqui, há bug de fluxo — nunca deve ocorrer.
      assert(
        false,
        'occurrences deve ser tratado pelo MapBottomSheet no Stack',
      );
      return const SizedBox.shrink();
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
            return const ActiveVisitSheet();
          }
          return VisitSheet(
            preSelectedClienteId: state.preSelectedClienteId,
            // Bug 1: scrollController conecta DraggableScrollableSheet ao
            // SingleChildScrollView interno para expansão correta via drag.
            scrollController: scrollController,
            onConfirm: (clientId, farmId, areaId, activity) async {
              final locationService = LocationService();
              final isAvailable = await locationService.checkAvailability();
              final fix = isAvailable
                  ? await locationService.getCurrentPosition()
                  : null;

              if (!context.mounted) return;

              if (fix == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível obter sua posição GPS.'),
                    backgroundColor: PremiumTokens.alertError,
                  ),
                );
                return;
              }

              await widgetRef
                  .read(visitControllerProvider.notifier)
                  .startSession(
                    clientId,
                    areaId,
                    activity,
                    fix.position.latitude,
                    fix.position.longitude,
                    farmId: farmId,
                  );

              if (!context.mounted) return;

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
