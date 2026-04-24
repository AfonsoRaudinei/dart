import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import '../../../../modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../../modules/map/presentation/widgets/visit_sheet.dart';
import '../../../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../../../ui/components/map/map_sheet_state.dart';
import '../../../../ui/components/map/map_sheets.dart';
import 'active_visit_sheet.dart';

/// Constrói o widget de conteúdo correto para cada [MapSheetType].
///
/// Extraído de `_PrivateMapSheets._buildSheetContent` — ADR-031 F3.
/// Função pura (sem estado próprio) — recebe todos os dados por parâmetro.
/// O switch aqui é o ponto de adição futura para [MapSheetType.clima] (DT-028).
Widget buildSheetContent(
  BuildContext context,
  WidgetRef ref,
  MapSheetState state,
  ScrollController scrollController,
  VoidCallback onArmOccurrenceMode,
) {
  switch (state.type) {
    case MapSheetType.layers:
      return SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        child: LayersSheet(onClose: () => Navigator.of(context).pop()),
      );
    case MapSheetType.occurrences:
      if (state.isCreatingOccurrence &&
          ref.read(pendingOccurrenceLocationProvider) != null) {
        final lat = ref.read(pendingOccurrenceLocationProvider)!.latitude;
        final lng = ref.read(pendingOccurrenceLocationProvider)!.longitude;
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
            if (context.mounted) onArmOccurrenceMode();
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
            return const ActiveVisitSheet();
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
