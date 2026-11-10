import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/design/sf_icons.dart';
import '../../../../../../ui/theme/premium/design_tokens.dart';
import 'package:soloforte_app/core/domain/occurrence_recomendacao_ordem.dart';

import '../../domain/occurrence.dart';
import '../../domain/occurrence_soy_age.dart';
import '../controllers/occurrence_controller.dart';
import '../occurrence_detail_report_actions.dart';
import '../occurrence_form_apply.dart';
import '../providers/occurrence_location_provider.dart';
import 'occurrence_andamento_section.dart';
import 'occurrence_detail_close_button.dart';
import 'occurrence_creation_sheet.dart';
import 'occurrence_detail_amostra_section.dart';
import 'occurrence_detail_pin_correction.dart';
import 'occurrence_detail_audio_section.dart';
import 'occurrence_detail_photo_section.dart';
import '../../../relatorio_visita/data/occurrence_audio_remote.dart';

part 'occurrence_detail_sheet_rows.dart';

/// Aplica os campos do formulário de edição sobre [current], preservando
/// campos que o formulário não edita (status, andamento, responsável).
/// `fieldId` só entra se [current] ainda não tinha talhão.
Occurrence applyOccurrenceFormEdit(
  Occurrence current,
  OccurrenceFormData data,
) {
  return occurrenceWithFormData(current, data).copyWith(
    status: current.status,
    fieldId: current.fieldId ?? data.fieldId,
    lat: data.latitude,
    long: data.longitude,
    geometry: jsonEncode({
      'type': 'Point',
      'coordinates': [data.longitude, data.latitude],
    }),
  );
}

/// Baixa o m4a do dono quando o arquivo local ainda não existe.
/// Supabase ausente ou dono vazio devolve false — o detalhe mantém o aviso.
Future<bool> _downloadOccurrenceDetailAudio(Occurrence occurrence) async {
  final userId = occurrence.ownerUserId?.trim() ?? '';
  if (userId.isEmpty) return false;
  final audioPath = occurrence.audioPath?.trim() ?? '';
  if (audioPath.isEmpty) return false;
  try {
    final supabase = Supabase.instance;
    if (!supabase.isInitialized) return false;
    final remoteId = occurrence.remoteId?.trim() ?? '';
    final occurrenceId = remoteId.isNotEmpty ? remoteId : occurrence.id;
    return OccurrenceAudioRemote(
      SupabaseOccurrenceAudioObjectStore(supabase.client),
    ).downloadIfMissing(
      userId: userId,
      occurrenceId: occurrenceId,
      audioPath: audioPath,
    );
  } catch (_) {
    return false;
  }
}

/// Sheet de detalhe de uma ocorrência existente.
///
/// Abre via tap no marcador no mapa ou lista.
/// Permite editar e excluir ocorrências próprias (não compartilhadas).
class OccurrenceDetailSheet extends ConsumerWidget {
  final Occurrence occurrence;
  final String? backRoute;
  final bool allowPinCorrection;
  final Future<void> Function(BuildContext context, Occurrence occurrence)?
      onExportLocation;

  const OccurrenceDetailSheet({
    super.key,
    required this.occurrence,
    this.backRoute,
    this.allowPinCorrection = false,
    this.onExportLocation,
  });

  static bool occurrencePinCorrectionEligible(Occurrence occurrence) {
    return occurrence.cachedByUserId == null &&
        occurrence.getCoordinates() != null;
  }

  // ── API pública ──────────────────────────────────────────────────────────

  static Future<void> show(
    BuildContext context,
    Occurrence occurrence, {
    String? backRoute,
    bool allowPinCorrection = false,
    Future<void> Function(BuildContext context, Occurrence occurrence)?
        onExportLocation,
  }) {
    HapticFeedback.lightImpact();
    return showSoloForteSheet(
      context: context,
      isScrollControlled: true,
      // Handle no conteúdo — Material handle + conteúdo = gesto de arraste ok.
      showDragHandle: false,
      enableDrag: true,
      builder: (_) => OccurrenceDetailSheet(
        occurrence: occurrence,
        backRoute: backRoute,
        allowPinCorrection: allowPinCorrection,
        onExportLocation: onExportLocation,
      ),
    );
  }

  // ── Helpers de categoria ─────────────────────────────────────────────────

  static String _labelForCategory(String? category) {
    return OccurrenceCategory.fromString(category).label;
  }

  void _goToMapPin(BuildContext context) {
    final coords = occurrence.getCoordinates();
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta ocorrência não tem ponto no mapa.')),
      );
      return;
    }
    final lat = coords['lat']!;
    final lng = coords['long']!;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    context.go(
      '${AppRoutes.map}?modo=foco&lat=${lat.toStringAsFixed(6)}'
      '&lng=${lng.toStringAsFixed(6)}',
    );
  }

  static Color _colorForCategory(String? category) {
    return OccurrenceCategory.fromString(category).markerColor;
  }

  static Color _colorForUrgency(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'alta':
        return PremiumTokens.alertError;
      case 'baixa':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  static String _labelForUrgency(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'alta':
        return 'Alta';
      case 'baixa':
        return 'Baixa';
      default:
        return 'Média';
    }
  }

  static String? _firstMetricLabel(Occurrence occurrence) {
    if (occurrence.metricasJson == null) return null;
    const labels = ['Nenhum', 'Leve', 'Moderado', 'Severo'];
    try {
      final map = jsonDecode(occurrence.metricasJson!) as Map<String, dynamic>;
      for (final metrics in map.values) {
        if (metrics is! Map<String, dynamic>) continue;
        for (final entry in metrics.entries) {
          final value = entry.value;
          if (value is int && value > 0) {
            final metricName = switch (entry.key) {
              'incidencia' => 'Incidência',
              'severidade' => 'Severidade',
              'desfolha' => 'Desfolha',
              'infestacao' => 'Infestação',
              'acamamento' => 'Acamamento',
              'status' => 'Status Hídrico',
              _ => entry.key,
            };
            return '$metricName: ${labels[value.clamp(0, 3)]}';
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    Occurrence live,
  ) async {
    final coords = live.getCoordinates();
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem ponto no mapa para editar.')),
      );
      return;
    }

    // Antes do pop: ref e context do detalhe não sobrevivem.
    final navigator = Navigator.of(context);
    final sheetHostContext = navigator.context;
    final repository = ref.read(occurrenceRepositoryProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    navigator.pop();
    if (!sheetHostContext.mounted) return;
    await showSoloForteSheet<void>(
      context: sheetHostContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.92,
        child: OccurrenceCreationSheet(
          latitude: coords['lat']!,
          longitude: coords['long']!,
          initialOccurrence: live,
          onCancel: () => Navigator.of(sheetContext).pop(),
          onConfirm: (data) async {
            final saved = await updateLiveOccurrence(
              repository,
              live,
              (current) => applyOccurrenceFormEdit(current, data),
            );
            container.invalidate(occurrencesListProvider);
            if (!sheetContext.mounted) return;
            if (!saved) {
              ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
                const SnackBar(content: Text(kOccurrenceDeletedMessage)),
              );
            }
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Occurrence live,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir ocorrência?'),
        content: const Text(
          'A ocorrência será ocultada do mapa e marcada para sincronização.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(occurrenceRepositoryProvider)
        .softDeleteOccurrence(live.id);
    ref.invalidate(occurrencesListProvider);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ocorrência excluída.')),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = SoloForteSheetVisuals.of(context);
    final live = resolveLiveOccurrence(
      ref.watch(occurrencesListProvider).valueOrNull,
      occurrence,
    );
    final isReadOnly = live.cachedByUserId != null;
    final isIos = v.isIos;
    final isDark =
        !isIos && Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _colorForCategory(live.category);
    final urgencyColor = _colorForUrgency(live.type);
    final categoryLabel = _labelForCategory(live.category);
    final urgencyLabel = _labelForUrgency(live.type);
    final metricLabel = _firstMetricLabel(live);
    final coords = live.getCoordinates();
    final hasMapPin = coords != null;
    final location = coords == null && (live.fieldId?.isEmpty ?? true)
        ? null
        : ref
            .watch(
              occurrenceLocationProvider((
                fieldId: live.fieldId,
                fazendaId: null,
                talhaoNome: null,
                lat: coords?['lat'] ?? 0,
                lng: coords?['long'] ?? 0,
              )),
            )
            .valueOrNull;

    final sheetBg = isIos
        ? v.sheetBackground
        : (isDark ? PremiumTokens.surfaceDark : context.premiumSurface);
    final sheetRadius = isIos
        ? v.sheetRadius
        : PremiumTokens.borderRadiusLg;
    final handleColor = isIos
        ? v.handleColor
        : (isDark ? const Color(0xFF545458) : const Color(0xFFC5C5C7));
    final titleColor = isIos
        ? v.titleColor
        : (isDark
            ? PremiumTokens.textPrimaryDark
            : context.premiumTextPrimary);
    final dividerColor = isIos
        ? v.rowDivider
        : (isDark ? PremiumTokens.hairlineDark : context.premiumHairline);
    final cardBg = isIos
        ? v.cardBackground
        : (isDark ? const Color(0xFF2C2C2E) : context.premiumBackground);
    final cardRadius = isIos
        ? v.cardRadius
        : PremiumTokens.borderRadiusSm;

    final formattedDate = DateFormat(
      "dd 'de' MMMM 'de' yyyy 'às' HH:mm",
      'pt_BR',
    ).format(live.createdAt);
    final ordem = OccurrenceRecomendacaoOrdem.resolve(
      acao: live.recomendacaoAcao,
      dose: live.recomendacaoDose,
      quando: live.recomendacaoQuando,
      legacy: live.recomendacoes,
    );
    final estadioComIdade = occurrenceEstadioDisplay(live);
    final detailRows = <_DetailRowData>[
      if (live.clientId != null && live.clientId!.isNotEmpty)
        _DetailRowData(
          icon: SFIcons.person,
          label: 'Cliente',
          valueBuilder: (context) => FutureBuilder(
            future: ref
                .read(clientLookupProvider)
                .findById(live.clientId!),
            builder: (context, snapshot) => Text(
              snapshot.data?.name ?? 'Cliente não encontrado',
              style: _DetailRow.valueStyle(context, isDark, isIos: isIos),
            ),
          ),
        ),
      if (location?.farmName case final farmName?)
        _DetailRowData(
          icon: SFIcons.agriculture,
          label: 'Fazenda',
          value: farmName,
        ),
      if (location != null)
        _DetailRowData(
          icon: SFIcons.agriculture,
          label: 'Talhão',
          value: location.fieldName,
        ),
      _DetailRowData(
        icon: SFIcons.description,
        label: 'Descrição',
        value: live.description.isNotEmpty
            ? live.description
            : 'Sem descrição — toque em Editar para preencher',
      ),
      for (final row in ordem.rows)
        _DetailRowData(
          icon: SFIcons.description,
          label: row.label,
          value: row.value,
          selectable: true,
        ),
      if (metricLabel != null)
        _DetailRowData(
          icon: SFIcons.barChart,
          label: 'Indicador',
          value: metricLabel,
        ),
      if (estadioComIdade.isNotEmpty)
        _DetailRowData(
          icon: SFIcons.leaf,
          label: 'Estádio fenológico',
          value: estadioComIdade,
        ),
      if (live.cultivar != null && live.cultivar!.isNotEmpty)
        _DetailRowData(
          icon: SFIcons.agriculture,
          label: 'Cultivar',
          value: live.cultivar!,
        ),
      if (live.cultura?.trim().isNotEmpty == true)
        _DetailRowData(
          icon: SFIcons.agriculture,
          label: 'Cultura',
          value: live.cultura!.trim(),
        ),
      if (live.safra?.trim().isNotEmpty == true)
        _DetailRowData(
          icon: SFIcons.calendar,
          label: 'Safra',
          value: live.safra!.trim(),
        ),
      if (live.dataPlantio != null &&
          live.dataPlantio!.isNotEmpty)
        _DetailRowData(
          icon: SFIcons.calendar,
          label: live.dataFimPlantio?.isNotEmpty == true
              ? 'Início do plantio'
              : 'Data de plantio',
          value: live.dataPlantio!,
        ),
      if (live.dataFimPlantio?.isNotEmpty == true)
        _DetailRowData(
          icon: SFIcons.calendar,
          label: 'Término do plantio',
          value: live.dataFimPlantio!,
        ),
      if (occurrenceCicloLabel(live.cicloDias) case final cicloLabel?)
        _DetailRowData(
          icon: SFIcons.calendar,
          label: 'Ciclo',
          value: cicloLabel,
        ),
      if (live.dataEmergencia?.isNotEmpty == true)
        _DetailRowData(
          icon: SFIcons.calendar, label: 'Data de emergência',
          value: live.dataEmergencia!),
      if (live.sementesPorMetro != null)
        _DetailRowData(
          icon: SFIcons.agriculture, label: 'Sementes por metro',
          value: '${live.sementesPorMetro}'),
      if (live.estandePlantas != null)
        _DetailRowData(
          icon: SFIcons.agriculture, label: 'Estande de plantas',
          value: '${live.estandePlantas}'),
      if (live.avaliacaoPlantio == 'boa' ||
          live.avaliacaoPlantio == 'ruim')
        _DetailRowData(
          icon: SFIcons.agriculture, label: 'Avaliação do plantio',
          value: live.avaliacaoPlantio == 'boa' ? 'Boa' : 'Ruim'),
      if (live.objetivoPlantio?.isNotEmpty == true)
        _DetailRowData(
          icon: SFIcons.agriculture, label: 'Objetivo',
          value: live.objetivoPlantio!),
      if (live.externalSource != null)
        _DetailRowData(
          icon: SFIcons.science,
          label: 'Origem externa',
          value: live.externalSource!,
        ),
      if (live.externalAnalysisId != null)
        _DetailRowData(
          icon: SFIcons.description,
          label: 'ID da análise',
          value: live.externalAnalysisId!,
        ),
      if (_formatPayload(live.analysisPayloadJson) != null)
        _DetailRowData(
          icon: SFIcons.barChart,
          label: 'Dados da análise',
          value: _formatPayload(live.analysisPayloadJson)!,
        ),
      _DetailRowData(
        icon: SFIcons.calendar,
        label: 'Registrada em',
        value: formattedDate,
      ),
    ];

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              // Modal já pinta prata iOS — evitar segundo painel opaco (“dois sheets”).
              color: isIos ? Colors.transparent : sheetBg,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(sheetRadius)),
              boxShadow: isIos ? null : PremiumTokens.premiumShadow,
            ),
            child: ListView(
              controller: scrollController,
              children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: v.handleSize.width,
                  height: v.handleSize.height,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    if (backRoute != null) ...[
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: isIos
                              ? v.arrowColor
                              : null,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final router = GoRouter.of(context);
                          final route = backRoute!;
                          Navigator.of(context).pop();
                          router.go(route);
                        },
                        tooltip: 'Voltar',
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryLabel,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              color: titleColor,
                            ),
                          ),
                          if (!isAreaVisitadaCategory(
                            live.category,
                          )) ...[
                            const SizedBox(height: 4),
                            _HeaderChip(
                              label: 'Urgência $urgencyLabel',
                              color: urgencyColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasMapPin)
                      IconButton(
                        tooltip: 'Ver no mapa',
                        icon: Icon(
                          SFIcons.pinFill,
                          color: isIos
                              ? v.iconStroke
                              : categoryColor,
                          size: 22,
                        ),
                        onPressed: () => _goToMapPin(context),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  thickness: PremiumTokens.hairlineThickness,
                  color: dividerColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              OccurrenceDetailPhotoSection(
                occurrence: live,
                cardBg: cardBg,
                cardRadius: cardRadius,
                isIos: isIos,
                isDark: isDark,
              ),
              OccurrenceDetailAudioSection(
                occurrence: live,
                cardBg: cardBg,
                cardRadius: cardRadius,
                isIos: isIos,
                isDark: isDark,
                downloadMissing: _downloadOccurrenceDetailAudio,
              ),
              OccurrenceDetailAmostraSection(
                occurrence: live,
                cardBg: cardBg,
                cardRadius: cardRadius,
                isIos: isIos,
                isDark: isDark,
              ),
              OccurrenceAndamentoSection(
                occurrence: live,
                readOnly: isReadOnly,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: isIos
                        ? Border.all(color: v.cardBorder)
                        : null,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < detailRows.length; i++)
                        _DetailRow(
                          isDark: isDark,
                          isIos: isIos,
                          icon: detailRows[i].icon,
                          label: detailRows[i].label,
                          value: detailRows[i].value,
                          valueBuilder: detailRows[i].valueBuilder,
                          selectable: detailRows[i].selectable,
                          showDivider: i < detailRows.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
              if (OccurrenceDetailExportLocationButton.eligible(
                live,
                onExportLocation,
              )) ...[
                const SizedBox(height: 12),
                OccurrenceDetailExportLocationButton(
                  occurrence: live,
                  isIos: isIos,
                  accentColor: categoryColor,
                  onExportLocation: onExportLocation!,
                ),
              ],
              const SizedBox(height: 12),
              OccurrenceDetailReportActionsRow(
                occurrence: live,
                isIos: isIos,
              ),
              if (allowPinCorrection &&
                  occurrencePinCorrectionEligible(live)) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => launchOccurrencePinCorrectionSession(
                        context,
                        ref,
                        live,
                      ),
                      style: isIos
                          ? OutlinedButton.styleFrom(
                              foregroundColor: v.ghostText,
                              side: BorderSide(color: v.ghostBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  v.ghostRadius,
                                ),
                              ),
                            )
                          : null,
                      icon: Icon(
                        Icons.open_with_rounded,
                        size: 18,
                        color: isIos
                            ? v.iconStroke
                            : categoryColor,
                      ),
                      label: const Text('Corrigir posição'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (!isReadOnly)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openEditSheet(context, ref, live),
                          style: isIos
                              ? OutlinedButton.styleFrom(
                                  foregroundColor:
                                      v.ghostText,
                                  side: BorderSide(color: v.ghostBorder,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      v.ghostRadius,
                                    ),
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          onPressed: () => _confirmDelete(context, ref, live),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Excluir'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isReadOnly) const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OccurrenceDetailCloseButton(
                    isDark: isDark,
                    isIos: isIos,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ),
          );
        },
      ),
    );
  }

  static String? _formatPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(payload));
    } catch (_) {
      return payload;
    }
  }
}
