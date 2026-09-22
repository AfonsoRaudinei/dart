import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/contracts/i_active_visit_context_lookup.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart';
import '../../../../modules/consultoria/occurrences/presentation/coordinators/occurrence_close_coordinator.dart';
import '../../../../modules/consultoria/occurrences/presentation/coordinators/occurrence_form_guard.dart';
import '../../../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../../../modules/consultoria/occurrences/presentation/providers/occurrence_draft_provider.dart';
import '../../../../modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import '../../../../modules/marketing/domain/entities/marketing_case.dart';
import '../../../../modules/marketing/domain/enums/case_tipo.dart';
import '../../../../modules/marketing/presentation/screens/novo_case_type_sheets.dart';
import '../../../screens/map/handlers/novo_case_modal_launcher.dart';
import '../map_occurrence_post_create.dart';

/// O que marcar no ponto do mapa. A escolha fica no topo da mesma ficha.
enum MapMarkKind {
  resultado,
  antesDepois,
  avaliacao,
  areaVisitada,
  ocorrencia,
}

/// Uma ficha: cinco opções no topo, campos da opção escolhida embaixo.
class MapMarkSheet extends ConsumerStatefulWidget {
  final LatLng position;
  final ActiveVisitContext? visitContext;
  final VoidCallback onClose;

  const MapMarkSheet({
    super.key,
    required this.position,
    required this.visitContext,
    required this.onClose,
  });

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required LatLng position,
  }) async {
    final visit = await NovoCaseModalLauncher.loadActiveVisitContext(ref);
    if (!context.mounted) return;
    await showSoloForteSheet<void>(
      context: context,
      showDragHandle: false,
      maxHeightFraction: 0.92,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MapMarkSheet(
        position: position,
        visitContext: visit,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  @override
  ConsumerState<MapMarkSheet> createState() => _MapMarkSheetState();
}

class _MapMarkSheetState extends ConsumerState<MapMarkSheet> {
  MapMarkKind? _kind;
  OccurrenceFormGuard? _occurrenceGuard;

  void _select(MapMarkKind kind) {
    HapticFeedback.selectionClick();
    setState(() {
      _kind = kind;
      _occurrenceGuard = kind == MapMarkKind.ocorrencia ||
              kind == MapMarkKind.areaVisitada
          ? OccurrenceFormGuard()
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final isIos = soloForteSheetIsIos(context);
    final bg = isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
    return Material(
      color: bg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isIos
                      ? SoloForteSheetSkinIos.handleColor
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final kind in MapMarkKind.values) ...[
                    _MarkChoice(
                      label: _label(kind),
                      icon: _icon(kind),
                      selected: _kind == kind,
                      onTap: () => _select(kind),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final kind = _kind;
    if (kind == null) {
      final isIos = soloForteSheetIsIos(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Escolha o que marcar neste ponto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isIos
                  ? SoloForteSheetSkinIos.subtitleColor
                  : const Color(0xFF8E8E93),
            ),
          ),
        ),
      );
    }

    final lat = widget.position.latitude;
    final lng = widget.position.longitude;
    switch (kind) {
      case MapMarkKind.resultado:
      case MapMarkKind.antesDepois:
      case MapMarkKind.avaliacao:
        return KeyedSubtree(
          key: ValueKey(kind),
          child: _caseForm(kind, lat, lng),
        );
      case MapMarkKind.areaVisitada:
      case MapMarkKind.ocorrencia:
        return KeyedSubtree(
          key: ValueKey(kind),
          child: _occurrenceForm(
            lat: lat,
            lng: lng,
            initialCategory: kind == MapMarkKind.areaVisitada
                ? kOccurrenceAreaVisitadaCategory
                : null,
          ),
        );
    }
  }

  Widget _caseForm(MapMarkKind kind, double lat, double lng) {
    final tipo = switch (kind) {
      MapMarkKind.resultado => CaseTipo.resultado,
      MapMarkKind.antesDepois => CaseTipo.antesDepois,
      MapMarkKind.avaliacao => CaseTipo.avaliacao,
      MapMarkKind.areaVisitada || MapMarkKind.ocorrencia => CaseTipo.resultado,
    };
    Future<void> publicar(MarketingCase newCase) async {
      await NovoCaseModalLauncher.submitCaseFromMap(
        context: context,
        ref: ref,
        newCase: newCase,
      );
    }

    final sheet = switch (tipo) {
      CaseTipo.resultado => NovoResultadoCaseSheet(
          lat: lat,
          lng: lng,
          initialVisitContext: widget.visitContext,
          onClose: widget.onClose,
          onPublicar: publicar,
        ),
      CaseTipo.antesDepois => NovoAntesDepoisCaseSheet(
          lat: lat,
          lng: lng,
          initialVisitContext: widget.visitContext,
          onClose: widget.onClose,
          onPublicar: publicar,
        ),
      CaseTipo.avaliacao => NovaAvaliacaoCaseSheet(
          lat: lat,
          lng: lng,
          initialVisitContext: widget.visitContext,
          onClose: widget.onClose,
          onPublicar: publicar,
        ),
    };
    return sheet;
  }

  Widget _occurrenceForm({
    required double lat,
    required double lng,
    required String? initialCategory,
  }) {
    final guard = _occurrenceGuard ?? OccurrenceFormGuard();
    return OccurrenceCreationSheet(
      latitude: lat,
      longitude: lng,
      formGuard: guard,
      initialCategoryValue: initialCategory,
      onCancel: () async {
        final canClose = await OccurrenceCloseCoordinator.confirmDiscardIfDirty(
          context,
          guard: guard,
        );
        if (!canClose || !mounted) return;
        clearOccurrenceDraft(ref, lat, lng);
        widget.onClose();
      },
      onConfirm: (data) async {
        if (!data.hasValidMapPin) {
          throw StateError(
            'Ponto do mapa inválido. Toque novamente no mapa para marcar a ocorrência.',
          );
        }
        await ref.read(occurrenceControllerProvider).createOccurrence(
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
              metricasJson: data.metricasJson,
              nutrientesJson: data.nutrientesJson,
              categoriasJson: data.categoriasJson,
              notasCategoriasJson: data.notasCategoriasJson,
              fotosCategoriasJson: data.fotosCategoriasJson,
            );
        if (!mounted) return;
        clearOccurrenceDraft(ref, data.latitude, data.longitude);
        if (!mounted) return;
        await handleMapOccurrencePostCreate(
          context: context,
          data: data,
          onClose: widget.onClose,
        );
      },
    );
  }

  String _label(MapMarkKind kind) {
    return switch (kind) {
      MapMarkKind.resultado => 'Resultado',
      MapMarkKind.antesDepois => 'Antes/Depois',
      MapMarkKind.avaliacao => 'Avaliação',
      MapMarkKind.areaVisitada => 'Área Visitada',
      MapMarkKind.ocorrencia => 'Ocorrência',
    };
  }

  IconData _icon(MapMarkKind kind) {
    return switch (kind) {
      MapMarkKind.resultado => SFIcons.barChart,
      MapMarkKind.antesDepois => SFIcons.compareArrows,
      MapMarkKind.avaliacao => SFIcons.science,
      MapMarkKind.areaVisitada => SFIcons.pinFill,
      MapMarkKind.ocorrencia => SFIcons.warning,
    };
  }
}

class _MarkChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MarkChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final accent = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : const Color(0xFF1976D2);
    final bg = selected
        ? accent.withValues(alpha: 0.16)
        : (isIos
            ? SoloForteSheetSkinIos.cardBackground
            : const Color(0xFF2C2C2E));
    final fg = selected
        ? accent
        : (isIos ? SoloForteSheetSkinIos.titleColor : Colors.white);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
