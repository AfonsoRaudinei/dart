// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../domain/client.dart';
import 'farm_map_entry_sheet.dart';

// ── Sub-widgets públicos de ClientDetailScreen ────────────────────────────
// Extraídos para manter client_detail_screen.dart abaixo de 900 linhas.
// (Sprint 7 — Bounded Context Hygiene)

// ── Botão de ação rápida ──────────────────────────────────────────────────

class ClientActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ClientActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<ClientActionButton> createState() => _ClientActionButtonState();
}

class _ClientActionButtonState extends State<ClientActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      offset: Offset(0, 10),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: PremiumTokens.brandGreen,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.07,
                  color: context.premiumTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item de fazenda na listagem ───────────────────────────────────────────

class ClientFarmItem extends StatelessWidget {
  final String name;
  final String area;
  final VoidCallback? onTap;

  const ClientFarmItem({
    super.key,
    required this.name,
    required this.area,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.premiumSurface,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 10),
              blurRadius: 32,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                Text(
                  area,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFC7C7CC),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formatter: caixa alta automática ────────────────────────────────────

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

// ── Opção no modal de nova fazenda/talhão (iOS Premium) ──────────────────

class ClientModalOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ClientModalOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final accent = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : Theme.of(context).colorScheme.primary;
    final surface = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : context.premiumSurface;
    final border = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : context.premiumHairline;
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : context.premiumTextPrimary;
    final subtitleColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : context.premiumTextSecondary;
    final arrowColor = isIos
        ? SoloForteSheetSkinIos.arrowColor
        : const Color(0xFFC7C7CC);
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 16.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isIos
                      ? SoloForteSheetSkinIos.iconBackground
                      : accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    isIos ? SoloForteSheetSkinIos.iconRadius : 12,
                  ),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: arrowColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper: modal de adicionar talhão (desenhar / importar) ─────────────
// Função livre para evitar dependência do state — chamada com context+client.

void showAdicionarTalhaoModal(BuildContext context, Client client) {
  HapticFeedback.lightImpact();
  showSoloForteSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (sheetCtx) {
      final isIos = soloForteSheetIsIos(sheetCtx);
      final surface = isIos
          ? SoloForteSheetSkinIos.background
          : context.premiumSurface;
      final handle = isIos
          ? SoloForteSheetSkinIos.handleColor
          : context.premiumHairline;
      final titleColor = isIos
          ? SoloForteSheetSkinIos.titleColor
          : null;
      final subtitleColor = isIos
          ? SoloForteSheetSkinIos.subtitleColor
          : context.premiumTextSecondary;
      final radius =
          isIos ? SoloForteSheetSkinIos.sheetRadius : 24.0;

      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isIos)
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: handle,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
            else
              const SizedBox(height: 8),
            Text(
              'Adicionar Talhão',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Como deseja criar o novo talhão?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 24),
            // Opção 1: Desenhar
            ClientModalOption(
              icon: Icons.edit_location_alt_outlined,
              title: 'Desenhar no Mapa',
              subtitle: 'Toque no mapa para definir os vértices',
              onTap: () {
                Navigator.of(context).pop();
                HapticFeedback.selectionClick();
                showFarmMapEntrySheet(
                  context,
                  client: client,
                  mode: FarmMapEntryMode.draw,
                );
              },
            ),
            const SizedBox(height: 12),
            // Opção 2: Importar KML/KMZ
            ClientModalOption(
              icon: Icons.upload_file_outlined,
              title: 'Importar KML ou KMZ',
              subtitle: 'Selecione um arquivo do dispositivo',
              onTap: () {
                Navigator.of(context).pop();
                HapticFeedback.selectionClick();
                showFarmMapEntrySheet(
                  context,
                  client: client,
                  mode: FarmMapEntryMode.import,
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
