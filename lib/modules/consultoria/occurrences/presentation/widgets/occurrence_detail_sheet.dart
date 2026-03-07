import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../../modules/map/design/sf_icons.dart';
import '../../../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/occurrence.dart';

/// Sheet de detalhe de uma ocorrência existente.
///
/// Abre via [showModalBottomSheet] pelo tap no marcador no mapa.
/// Estado local efêmero — nenhum dado é alterado.
/// Fecha via [Navigator.of(context).pop()] interno — sem interferir no Map-First.
class OccurrenceDetailSheet extends StatelessWidget {
  final Occurrence occurrence;

  const OccurrenceDetailSheet({super.key, required this.occurrence});

  // ── API pública ──────────────────────────────────────────────────────────

  static Future<void> show(BuildContext context, Occurrence occurrence) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OccurrenceDetailSheet(occurrence: occurrence),
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
    switch ((category ?? '').toLowerCase()) {
      case 'doenca':
      case 'doença':
        return 'Doença';
      case 'insetos':
      case 'pragas':
        return 'Insetos / Pragas';
      case 'daninhas':
      case 'ervas_daninhas':
      case 'ervas daninhas':
        return 'Ervas Daninhas';
      case 'nutricional':
      case 'nutrientes':
        return 'Nutrientes';
      case 'agua':
      case 'água':
        return 'Estresse Hídrico';
      case 'amostra_solo':
      case 'amostra solo':
        return 'Amostra de Solo';
      default:
        return 'Sem categoria';
    }
  }

  // ── Cor e label de urgência ───────────────────────────────────────────────

  static Color _colorForUrgency(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'alta':
        return PremiumTokens.alertError;
      case 'baixa':
        return Colors.grey.shade500;
      default: // "média" ou qualquer outro valor
        return Colors.orange;
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urgencyColor = _colorForUrgency(occurrence.type);
    final categoryIcon = _iconForCategory(occurrence.category);
    final categoryLabel = _labelForCategory(occurrence.category);
    final urgencyLabel = _labelForUrgency(occurrence.type);

    final formattedDate =
        DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR')
            .format(occurrence.createdAt);

    final lat = occurrence.lat;
    final lng = occurrence.long;
    final coordsText = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
        : 'Sem coordenadas';

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? PremiumTokens.surfaceDark : PremiumTokens.surfaceLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(PremiumTokens.borderRadiusLg),
          ),
          boxShadow: PremiumTokens.premiumShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag pill ─────────────────────────────────────────────────
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

            // ── Header com ícone + categoria + urgência ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(categoryIcon, color: urgencyColor, size: 22),
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
                                : PremiumTokens.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: urgencyColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Urgência $urgencyLabel',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: urgencyColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Divisor ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                thickness: PremiumTokens.hairlineThickness,
                color: isDark
                    ? PremiumTokens.hairlineDark
                    : PremiumTokens.hairlineLight,
                height: 1,
              ),
            ),

            const SizedBox(height: 16),

            // ── Dados em lista Inset ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : PremiumTokens.backgroundLight,
                  borderRadius:
                      BorderRadius.circular(PremiumTokens.borderRadiusSm),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      isDark: isDark,
                      icon: SFIcons.description,
                      label: 'Descrição',
                      value: occurrence.description.isNotEmpty
                          ? occurrence.description
                          : 'Sem descrição',
                      showDivider: true,
                    ),
                    _DetailRow(
                      isDark: isDark,
                      icon: SFIcons.locationOn,
                      label: 'Coordenadas',
                      value: coordsText,
                      showDivider: true,
                    ),
                    if (occurrence.cultivar != null &&
                        occurrence.cultivar!.isNotEmpty)
                      _DetailRow(
                        isDark: isDark,
                        icon: SFIcons.agriculture,
                        label: 'Cultivar',
                        value: occurrence.cultivar!,
                        showDivider: true,
                      ),
                    if (occurrence.dataPlantio != null &&
                        occurrence.dataPlantio!.isNotEmpty)
                      _DetailRow(
                        isDark: isDark,
                        icon: SFIcons.calendar,
                        label: 'Data de Plantio',
                        value: occurrence.dataPlantio!,
                        showDivider: true,
                      ),
                    _DetailRow(
                      isDark: isDark,
                      icon: SFIcons.calendar,
                      label: 'Registrada em',
                      value: formattedDate,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Botão fechar ──────────────────────────────────────────────
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
    );
  }
}

// ── Subwidget: linha de detalhe ────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _DetailRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
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
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.4,
                        color: isDark
                            ? PremiumTokens.textPrimaryDark
                            : PremiumTokens.textPrimaryLight,
                      ),
                    ),
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
                  : PremiumTokens.hairlineLight,
              height: 1,
            ),
          ),
      ],
    );
  }
}

// ── Subwidget: botão fechar estilo Cupertino ──────────────────────────────

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
                  : PremiumTokens.backgroundLight,
              borderRadius:
                  BorderRadius.circular(PremiumTokens.borderRadiusMd),
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
                    : PremiumTokens.textPrimaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
