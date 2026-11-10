import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/coordinators/occurrence_close_coordinator.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/coordinators/occurrence_form_guard.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/models/occurrence_talhao_prefill.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/providers/occurrence_draft_provider.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/ui/screens/map/providers/occurrence_form_guard_provider.dart';

import 'map_occurrence_post_create.dart';

/// Talhão ativo sob o ponto, com cliente (fazenda opcional). Fora disso, null.
OccurrenceTalhaoPrefill? occurrenceTalhaoPrefillFor(
  DrawingController controller,
  LatLng point,
) {
  final feature = controller.findFeatureAt(point);
  if (feature == null) return null;
  final properties = feature.properties;
  return occurrenceTalhaoPrefillIfEligible(
    ativo: properties.ativo,
    fieldId: feature.id,
    nome: properties.nome,
    clienteId: properties.clienteId,
    fazendaId: properties.fazendaId,
    cultura: properties.cultura,
    material: properties.material,
    dataPlantio: properties.dataPlantio,
    dataEmergencia: properties.dataEmergencia,
    cicloDias: properties.cicloDias,
  );
}

/// Formulário de ocorrência do [MapBottomSheet]. Extraído para o sheet
/// permanecer dentro do teto de linhas.
Widget buildMapOccurrenceCreationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required bool Function() isMounted,
  required double latitude,
  required double longitude,
  required ScrollController scrollController,
  required OccurrenceFormGuard? formGuard,
  required String? initialCategory,
  required DrawingController drawingController,
  required VoidCallback onClose,
  required VoidCallback clearDraft,
}) {
  return OccurrenceCreationSheet(
    latitude: latitude,
    longitude: longitude,
    scrollController: scrollController,
    formGuard: formGuard,
    initialCategoryValue: initialCategory,
    liftStickyActionsForKeyboard: false,
    talhaoPrefill: occurrenceTalhaoPrefillFor(
      drawingController,
      LatLng(latitude, longitude),
    ),
    onCancel: () async {
      final canClose = await OccurrenceCloseCoordinator.confirmDiscardIfDirty(
        context,
        guard: formGuard,
      );
      if (!canClose || !isMounted()) return;
      clearDraft();
      ref.read(occurrenceFormGuardProvider.notifier).state = null;
      onClose();
    },
    onConfirm: (data) async {
      if (!data.hasValidMapPin) {
        throw StateError(
          'Ponto do mapa inválido. Toque novamente no mapa para marcar a ocorrência.',
        );
      }
      await ref
          .read(occurrenceControllerProvider)
          .createOccurrence(
            type: data.type,
            description: data.description,
            clientId: data.clientId,
            photoPath: data.photoPath,
            lat: data.latitude,
            long: data.longitude,
            category: data.category,
            status: 'draft',
            cultivar: data.cultivar,
            dataPlantio: data.dataPlantio,
            estadioFenologico: data.estadioFenologico,
            tipoOcorrencia: data.tipoOcorrencia,
            amostraSolo: data.amostraSolo,
            recomendacoes: data.recomendacoes,
            recomendacaoAcao: data.recomendacaoAcao,
            recomendacaoDose: data.recomendacaoDose,
            recomendacaoQuando: data.recomendacaoQuando,
            metricasJson: data.metricasJson,
            nutrientesJson: data.nutrientesJson,
            categoriasJson: data.categoriasJson,
            notasCategoriasJson: data.notasCategoriasJson,
            fotosCategoriasJson: data.fotosCategoriasJson,
            dataEmergencia: data.dataEmergencia,
            sementesPorMetro: data.sementesPorMetro,
            estandePlantas: data.estandePlantas,
            avaliacaoPlantio: data.avaliacaoPlantio,
            objetivoPlantio: data.objetivoPlantio,
            dataFimPlantio: data.dataFimPlantio,
            cicloDias: data.cicloDias,
            cultura: data.cultura,
            safra: data.safra,
            audioPath: data.audioPath,
            audioDurationSec: data.audioDurationSec,
            amostraCodigo: data.amostraCodigo,
            amostraColetor: data.amostraColetor,
            amostraTramite: data.amostraTramite,
            amostraLaudoTexto: data.amostraLaudoTexto,
            fieldId: data.fieldId,
          );
      if (!isMounted()) return;
      clearOccurrenceDraft(ref, data.latitude, data.longitude);
      if (!isMounted() || !context.mounted) return;
      await handleMapOccurrencePostCreate(
        context: context,
        data: data,
        onClose: onClose,
      );
    },
  );
}
