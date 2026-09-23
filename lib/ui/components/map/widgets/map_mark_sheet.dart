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
            _MarkKindToggleBar(
              selected: _kind,
              isIos: isIos,
              labelFor: _label,
              iconFor: _icon,
              onSelected: _select,
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

/// Pílulas horizontais (estilo Mail): peek na borda + fade quando há mais conteúdo.
class _MarkKindToggleBar extends StatefulWidget {
  final MapMarkKind? selected;
  final bool isIos;
  final String Function(MapMarkKind) labelFor;
  final IconData Function(MapMarkKind) iconFor;
  final ValueChanged<MapMarkKind> onSelected;

  const _MarkKindToggleBar({
    required this.selected,
    required this.isIos,
    required this.labelFor,
    required this.iconFor,
    required this.onSelected,
  });

  @override
  State<_MarkKindToggleBar> createState() => _MarkKindToggleBarState();
}

class _MarkKindToggleBarState extends State<_MarkKindToggleBar> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftFade = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncEdgeFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdgeFades());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncEdgeFades() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    final pixels = position.pixels;
    final showLeft = pixels > 6;
    final showRight = maxExtent > 6 && pixels < maxExtent - 6;
    if (showLeft == _showLeftFade && showRight == _showRightFade) return;
    setState(() {
      _showLeftFade = showLeft;
      _showRightFade = showRight;
    });
  }

  Color _sheetFadeColor() {
    return widget.isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = _sheetFadeColor();
    return Semantics(
      label:
          'Ações para marcar no ponto. Deslize horizontalmente para ver todas.',
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: SizedBox(
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 12),
                clipBehavior: Clip.hardEdge,
                itemCount: MapMarkKind.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final kind = MapMarkKind.values[index];
                  return _MarkToggleSegment(
                    label: widget.labelFor(kind),
                    icon: widget.iconFor(kind),
                    isSelected: widget.selected == kind,
                    onTap: () => widget.onSelected(kind),
                    isIos: widget.isIos,
                  );
                },
              ),
              if (_showLeftFade)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 28,
                  child: IgnorePointer(
                    child: _MarkScrollEdgeFade(
                      color: fadeColor,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              if (_showRightFade)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 40,
                  child: IgnorePointer(
                    child: _MarkScrollEdgeFade(
                      color: fadeColor,
                      alignment: Alignment.centerRight,
                      showChevron: true,
                      isIos: widget.isIos,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkScrollEdgeFade extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  final bool showChevron;
  final bool isIos;

  const _MarkScrollEdgeFade({
    required this.color,
    required this.alignment,
    this.showChevron = false,
    this.isIos = false,
  });

  @override
  Widget build(BuildContext context) {
    final begin = alignment == Alignment.centerLeft
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final end = alignment == Alignment.centerLeft
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final chevronColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : Colors.white.withValues(alpha: 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
      child: showChevron
          ? Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: chevronColor,
                ),
              ),
            )
          : null,
    );
  }
}

class _MarkToggleSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isIos;

  const _MarkToggleSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isIos,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : const Color(0xFF1976D2);
    final idleBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : Colors.white.withValues(alpha: 0.08);
    final idleBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : Colors.white.withValues(alpha: 0.06);
    final idleLabel = isIos
        ? SoloForteSheetSkinIos.titleColor
        : const Color(0xFFE5E5EA);
    final selectedLabel =
        isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : idleBg,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: idleBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? selectedLabel : idleLabel,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedLabel : idleLabel,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
