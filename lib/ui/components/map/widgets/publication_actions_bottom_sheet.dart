import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../theme/premium/design_tokens.dart';
import '../../premium/premium_glass_panel.dart';

class PublicationActionsBottomSheet extends StatelessWidget {
  final VoidCallback onResultado;
  final VoidCallback onAntesDepois;
  final VoidCallback onAvaliacao;
  final VoidCallback onOcorrencia;
  final VoidCallback onFotoRapida;
  final VoidCallback onInversaoVegetal;

  const PublicationActionsBottomSheet({
    super.key,
    required this.onResultado,
    required this.onAntesDepois,
    required this.onAvaliacao,
    required this.onOcorrencia,
    required this.onFotoRapida,
    required this.onInversaoVegetal,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onResultado,
    required VoidCallback onAntesDepois,
    required VoidCallback onAvaliacao,
    required VoidCallback onOcorrencia,
    required VoidCallback onFotoRapida,
    required VoidCallback onInversaoVegetal,
  }) {
    return showSoloForteSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      builder: (_) => PublicationActionsBottomSheet(
        onResultado: onResultado,
        onAntesDepois: onAntesDepois,
        onAvaliacao: onAvaliacao,
        onOcorrencia: onOcorrencia,
        onFotoRapida: onFotoRapida,
        onInversaoVegetal: onInversaoVegetal,
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

    return SafeArea(
      top: false,
      child: PremiumGlassPanel(
        isDark: true,
        padding: EdgeInsets.zero,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
          decoration: BoxDecoration(
            color: PremiumTokens.surfaceDark.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
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
                    color: Colors.white.withValues(alpha: 0.34),
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
                  title: 'Antes/Depois',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _select(context, onAntesDepois),
                ),
                _ActionRow(
                  icon: SFIcons.science,
                  title: 'Avaliação',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _select(context, onAvaliacao),
                ),
                _ActionRow(
                  icon: SFIcons.warning,
                  title: 'Ocorrência',
                  color: PremiumTokens.alertWarning,
                  onTap: () => _select(context, onOcorrencia),
                ),
                _ActionRow(
                  icon: SFIcons.image,
                  title: 'Foto rápida',
                  color: const Color(0xFFAF52DE),
                  onTap: () => _select(context, onFotoRapida),
                ),
                _ActionRow(
                  icon: SFIcons.leaf,
                  title: 'Inversão vegetal',
                  color: PremiumTokens.brandGreen,
                  showDivider: false,
                  onTap: () => _select(context, onInversaoVegetal),
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

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
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
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    SFIcons.chevronRight,
                    color: Colors.white.withValues(alpha: 0.32),
                    size: 18,
                  ),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 48,
                color: Colors.white.withValues(alpha: 0.08),
              ),
          ],
        ),
      ),
    );
  }
}
