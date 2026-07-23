import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

import '../../../../../../core/design/sf_icons.dart';
import '../../../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/occurrence.dart';
import '../controllers/occurrence_controller.dart';
import 'occurrence_creation_sheet.dart';

/// Sheet de detalhe de uma ocorrência existente.
///
/// Abre via tap no marcador no mapa ou lista.
/// Permite editar e excluir ocorrências próprias (não compartilhadas).
class OccurrenceDetailSheet extends ConsumerWidget {
  final Occurrence occurrence;
  final String? backRoute;

  const OccurrenceDetailSheet({
    super.key,
    required this.occurrence,
    this.backRoute,
  });

  bool get _isReadOnly => occurrence.cachedByUserId != null;

  // ── API pública ──────────────────────────────────────────────────────────

  static Future<void> show(
    BuildContext context,
    Occurrence occurrence, {
    String? backRoute,
  }) {
    HapticFeedback.lightImpact();
    return showSoloForteSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => OccurrenceDetailSheet(
        occurrence: occurrence,
        backRoute: backRoute,
      ),
    );
  }

  // ── Helpers de categoria ─────────────────────────────────────────────────

  static IconData _iconForCategory(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'doenca':
      case 'doença':
        return SFIcons.coronavirus;
      case 'insetos':
      case 'pragas':
        return SFIcons.bugReport;
      case 'daninhas':
      case 'ervas_daninhas':
      case 'ervas daninhas':
        return SFIcons.grass;
      case 'nutricional':
      case 'nutrientes':
        return SFIcons.science;
      case 'agua':
      case 'água':
        return SFIcons.waterDrop;
      case 'amostra_solo':
      case 'amostra solo':
        return Icons.biotech_outlined;
      default:
        return SFIcons.locationOn;
    }
  }

  static String _labelForCategory(String? category) {
    return OccurrenceCategory.fromString(category).label;
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

  static String _labelForStatus(String? status) {
    return status == 'confirmed' ? 'Confirmada' : 'Rascunho';
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

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref) async {
    final coords = occurrence.getCoordinates();
    if (coords == null) return;

    Navigator.of(context).pop();
    await showSoloForteSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.92,
        child: OccurrenceCreationSheet(
          latitude: coords['lat']!,
          longitude: coords['long']!,
          initialOccurrence: occurrence,
          onCancel: () => Navigator.of(sheetContext).pop(),
          onConfirm: (data) async {
            await ref.read(occurrenceRepositoryProvider).updateOccurrence(
              occurrence.copyWith(
                type: data.type,
                description: data.description,
                clientId: data.clientId,
                photoPath: data.photoPath,
                category: data.category,
                status: occurrence.status,
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
              ),
            );
            ref.invalidate(occurrencesListProvider);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
        .softDeleteOccurrence(occurrence.id);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _colorForCategory(occurrence.category);
    final urgencyColor = _colorForUrgency(occurrence.type);
    final categoryIcon = _iconForCategory(occurrence.category);
    final categoryLabel = _labelForCategory(occurrence.category);
    final urgencyLabel = _labelForUrgency(occurrence.type);
    final category = OccurrenceCategory.fromString(occurrence.category);
    final metricLabel = _firstMetricLabel(occurrence);

    final formattedDate = DateFormat(
      "dd 'de' MMMM 'de' yyyy 'às' HH:mm",
      'pt_BR',
    ).format(occurrence.createdAt);

    final coordinates = occurrence.getCoordinates();
    final coordsText = coordinates != null
        ? '${coordinates['lat']!.toStringAsFixed(5)}, '
              '${coordinates['long']!.toStringAsFixed(5)}'
        : 'Sem coordenadas';

    final detailRows = <_DetailRowData>[
      if (occurrence.clientId != null && occurrence.clientId!.isNotEmpty)
        _DetailRowData(
          icon: SFIcons.person,
          label: 'Cliente',
          valueBuilder: (context) => FutureBuilder(
            future: ref
                .read(clientLookupProvider)
                .findById(occurrence.clientId!),
            builder: (context, snapshot) => Text(
              snapshot.data?.name ?? 'Cliente não encontrado',
              style: _DetailRow.valueStyle(isDark),
            ),
          ),
        ),
      _DetailRowData(
        icon: SFIcons.info,
        label: 'Status',
        value: _labelForStatus(occurrence.status),
      ),
      _DetailRowData(
        icon: SFIcons.description,
        label: 'Descrição',
        value: occurrence.description.isNotEmpty
            ? occurrence.description
            : 'Sem descrição — toque em Editar para preencher',
      ),
      if (occurrence.recomendacoes != null &&
          occurrence.recomendacoes!.trim().isNotEmpty)
        _DetailRowData(
          icon: Icons.lightbulb_outline,
          label: 'Recomendações',
          value: occurrence.recomendacoes!,
        ),
      if (metricLabel != null)
        _DetailRowData(
          icon: SFIcons.barChart,
          label: 'Indicador',
          value: metricLabel,
        ),
      if (occurrence.estadioFenologico != null &&
          occurrence.estadioFenologico!.isNotEmpty)
        _DetailRowData(
          icon: SFIcons.leaf,
          label: 'Estádio fenológico',
          value: occurrence.estadioFenologico!,
        ),
      _DetailRowData(
        icon: SFIcons.locationOn,
        label: 'Coordenadas',
        value: coordsText,
      ),
      if (occurrence.cultivar != null && occurrence.cultivar!.isNotEmpty)
        _DetailRowData(
          icon: SFIcons.agriculture,
          label: 'Cultivar',
          value: occurrence.cultivar!,
        ),
      if (occurrence.dataPlantio != null &&
          occurrence.dataPlantio!.isNotEmpty)
        _DetailRowData(
          icon: SFIcons.calendar,
          label: 'Data de plantio',
          value: occurrence.dataPlantio!,
        ),
      if (occurrence.externalSource != null)
        _DetailRowData(
          icon: SFIcons.science,
          label: 'Origem externa',
          value: occurrence.externalSource!,
        ),
      if (occurrence.externalAnalysisId != null)
        _DetailRowData(
          icon: SFIcons.description,
          label: 'ID da análise',
          value: occurrence.externalAnalysisId!,
        ),
      if (_formatPayload(occurrence.analysisPayloadJson) != null)
        _DetailRowData(
          icon: SFIcons.barChart,
          label: 'Dados da análise',
          value: _formatPayload(occurrence.analysisPayloadJson)!,
        ),
      _DetailRowData(
        icon: SFIcons.calendar,
        label: 'Registrada em',
        value: formattedDate,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? PremiumTokens.surfaceDark
              : context.premiumSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(PremiumTokens.borderRadiusLg),
          ),
          boxShadow: PremiumTokens.premiumShadow,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF545458)
                        : const Color(0xFFC5C5C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    if (backRoute != null) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                              color: isDark
                                  ? PremiumTokens.textPrimaryDark
                                  : context.premiumTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _HeaderChip(
                                label: 'Urgência $urgencyLabel',
                                color: urgencyColor,
                              ),
                              const SizedBox(width: 6),
                              _HeaderChip(
                                label: _labelForStatus(occurrence.status),
                                color: occurrence.status == 'confirmed'
                                    ? const Color(0xFF34C759)
                                    : const Color(0xFFFF9500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(categoryIcon, color: categoryColor, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  thickness: PremiumTokens.hairlineThickness,
                  color: isDark
                      ? PremiumTokens.hairlineDark
                      : context.premiumHairline,
                  height: 1,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : context.premiumBackground,
                    borderRadius: BorderRadius.circular(
                      PremiumTokens.borderRadiusSm,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < detailRows.length; i++)
                        _DetailRow(
                          isDark: isDark,
                          icon: detailRows[i].icon,
                          label: detailRows[i].label,
                          value: detailRows[i].value,
                          valueBuilder: detailRows[i].valueBuilder,
                          showDivider: i < detailRows.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!_isReadOnly)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openEditSheet(context, ref),
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
                          onPressed: () => _confirmDelete(context, ref),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Excluir'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_isReadOnly) const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CupertinoCloseButton(
                    isDark: isDark,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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

class _DetailRowData {
  final IconData icon;
  final String label;
  final String? value;
  final WidgetBuilder? valueBuilder;

  const _DetailRowData({
    required this.icon,
    required this.label,
    this.value,
    this.valueBuilder,
  });
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String? value;
  final WidgetBuilder? valueBuilder;
  final bool showDivider;

  const _DetailRow({
    required this.isDark,
    required this.icon,
    required this.label,
    this.value,
    this.valueBuilder,
    required this.showDivider,
  });

  static TextStyle valueStyle(bool isDark) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.4,
      color: isDark
          ? PremiumTokens.textPrimaryDark
          : PremiumTokens.textPrimaryLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6C6C70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.07,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6C6C70),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (valueBuilder != null)
                      valueBuilder!(context)
                    else
                      Text(value ?? '—', style: valueStyle(isDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Divider(
              thickness: PremiumTokens.hairlineThickness,
              color: isDark
                  ? PremiumTokens.hairlineDark
                  : context.premiumHairline,
              height: 1,
            ),
          ),
      ],
    );
  }
}

class CupertinoCloseButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const CupertinoCloseButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<CupertinoCloseButton> createState() => _CupertinoCloseButtonState();
}

class _CupertinoCloseButtonState extends State<CupertinoCloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF2C2C2E)
                  : context.premiumBackground,
              borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
            ),
            alignment: Alignment.center,
            child: Text(
              'Fechar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: widget.isDark
                    ? PremiumTokens.textPrimaryDark
                    : context.premiumTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
