import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../theme/premium/design_tokens.dart';
import '../../premium/premium_glass_panel.dart';

class PublicationActionsBottomSheet extends StatelessWidget {
  final VoidCallback onResultado;
  final VoidCallback onAntesDepois;
  final VoidCallback onAvaliacao;
  final VoidCallback onAreaVisitada;
  final VoidCallback onOcorrencia;

  const PublicationActionsBottomSheet({
    super.key,
    required this.onResultado,
    required this.onAntesDepois,
    required this.onAvaliacao,
    required this.onAreaVisitada,
    required this.onOcorrencia,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onResultado,
    required VoidCallback onAntesDepois,
    required VoidCallback onAvaliacao,
    required VoidCallback onAreaVisitada,
    required VoidCallback onOcorrencia,
  }) {
    return showSoloForteSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      builder: (_) => PublicationActionsBottomSheet(
        onResultado: onResultado,
        onAntesDepois: onAntesDepois,
        onAvaliacao: onAvaliacao,
        onAreaVisitada: onAreaVisitada,
        onOcorrencia: onOcorrencia,
      ),
    );
  }

  void _select(BuildContext context, VoidCallback action) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
        final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;

    if (isIos) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
          child: Container(
            decoration: BoxDecoration(
              color: v.cardBackground,
              borderRadius:
                  BorderRadius.circular(v.cardRadius),
              border: Border.all(color: v.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionRow(
                  icon: SFIcons.barChart,
                  title: 'Resultado',
                  color: v.iconStroke,
                  isIos: true,
                  onTap: () => _select(context, onResultado),
                ),
                _ActionRow(
                  icon: SFIcons.compareArrows,
                  title: 'Avaliação',
                  color: v.iconStroke,
                  isIos: true,
                  onTap: () => _select(context, onAntesDepois),
                ),
                _ActionRow(
                  icon: SFIcons.pinFill,
                  title: 'Área Visitada',
                  color: v.iconStroke,
                  isIos: true,
                  onTap: () => _select(context, onAreaVisitada),
                ),
                _ActionRow(
                  icon: SFIcons.warning,
                  title: 'Ocorrência',
                  color: v.iconStroke,
                  isIos: true,
                  showDivider: false,
                  onTap: () => _select(context, onOcorrencia),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: PremiumGlassPanel(
        isDark: true,
        padding: EdgeInsets.zero,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
          decoration: BoxDecoration(
            color: v.sheetBackground.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: v.onSheetDivider,
                width: 0.5,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: v.handleColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                _ActionRow(
                  icon: SFIcons.barChart,
                  title: 'Resultado',
                  color: PremiumTokens.brandGreen,
                  onTap: () => _select(context, onResultado),
                ),
                _ActionRow(
                  icon: SFIcons.compareArrows,
                  title: 'Avaliação',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _select(context, onAntesDepois),
                ),
                _ActionRow(
                  icon: SFIcons.pinFill,
                  title: 'Área Visitada',
                  color: const Color(0xFF607D8B),
                  onTap: () => _select(context, onAreaVisitada),
                ),
                _ActionRow(
                  icon: SFIcons.warning,
                  title: 'Ocorrência',
                  color: PremiumTokens.alertWarning,
                  showDivider: false,
                  onTap: () => _select(context, onOcorrencia),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isIos;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.showDivider = true,
    this.isIos = false,
  });

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final titleColor = v.titleColor;
    final arrowColor = v.isIos ? v.arrowColor : v.subtitleColor;
    final dividerColor = v.isIos ? v.rowDivider : v.onSheetDivider;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  if (isIos) const SizedBox(width: 12),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isIos
                          ? v.iconBackground
                          : color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(isIos ? 999 : 10),
                    ),
                    child: Icon(
                      icon,
                      color: isIos ? v.iconStroke : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(SFIcons.chevronRight, color: arrowColor, size: 18),
                  if (isIos) const SizedBox(width: 12),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: isIos ? 60 : 48,
                color: dividerColor,
              ),
          ],
        ),
      ),
    );
  }
}
