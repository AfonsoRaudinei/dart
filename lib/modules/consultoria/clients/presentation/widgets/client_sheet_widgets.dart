import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_form_padding.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Tokens visuais compartilhados pelos sheets premium de clientes/consultoria.
class ClientSheetVisuals {
  ClientSheetVisuals._(this.context);

  factory ClientSheetVisuals.of(BuildContext context) =>
      ClientSheetVisuals._(context);

  final BuildContext context;

  bool get isIos => soloForteSheetIsIos(context);

  Color get sheetBg => isIos ? Colors.transparent : Colors.white;

  double get sheetRadius => isIos ? SoloForteSheetSkinIos.sheetRadius : 24.0;

  Color? get titleColor =>
      isIos ? SoloForteSheetSkinIos.titleColor : null;

  Color get muted =>
      isIos ? SoloForteSheetSkinIos.subtitleColor : SoloForteSheetTokens.inputHint;

  Color get accent =>
      isIos ? SoloForteSheetSkinIos.iconStroke : PremiumTokens.brandGreen;

  Color get cardBg =>
      isIos ? SoloForteSheetSkinIos.cardBackground : const Color(0xFFEFFAF2);

  Color get cardBorder =>
      isIos ? SoloForteSheetSkinIos.cardBorder : const Color(0xFFE2E2E8);

  double get cardRadius => isIos ? SoloForteSheetSkinIos.cardRadius : 16.0;

  double get inputRadius =>
      isIos ? SoloForteSheetTokens.inputRadius : visualsCardRadiusFallback;

  static const double visualsCardRadiusFallback = 12.0;

  Color get arrowColor =>
      isIos ? SoloForteSheetSkinIos.arrowColor : const Color(0xFFC7C7CC);

  Color get dividerColor =>
      isIos ? SoloForteSheetSkinIos.rowDivider : const Color(0xFFE5E5EA);

  Color get ctaBg =>
      isIos ? SoloForteSheetSkinIos.ctaBackground : PremiumTokens.brandGreen;

  Color get ctaFg => isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;

  double get ctaRadius => isIos ? SoloForteSheetSkinIos.ctaRadius : 13.0;

  Color get ghostBorder =>
      isIos ? SoloForteSheetSkinIos.ghostBorder : const Color(0xFFE2E2E8);

  Color get ghostText =>
      isIos ? SoloForteSheetSkinIos.ghostText : PremiumTokens.brandGreen;

  double get ghostRadius => isIos ? SoloForteSheetSkinIos.ghostRadius : 13.0;

  /// Sheets de cliente usam fundo claro — inputs seguem estilo iOS agrupado,
  /// não o painel escuro de [SoloForteSheetTokens] (mapa/ocorrências).
  Color get inputFill =>
      isIos ? SoloForteSheetSkinIos.cardBackground : const Color(0xFFF2F2F7);

  Color get inputText =>
      isIos ? SoloForteSheetSkinIos.titleColor : const Color(0xFF1C1C1E);

  Color get inputHint =>
      isIos ? SoloForteSheetSkinIos.subtitleColor : const Color(0xFF8E8E93);
}

/// Scaffold padrão: handle, título, subtítulo opcional e corpo.
class ClientSheetScaffold extends StatelessWidget {
  const ClientSheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.contextLine,
    this.showHandle = true,
    this.banner,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final String? contextLine;
  final bool showHandle;
  final Widget? banner;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.sheetBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(visuals.sheetRadius),
        ),
      ),
      child: Padding(
        padding: clientSheetFormPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) ...[
              Center(
                child: Container(
                  width: visuals.isIos
                      ? SoloForteSheetSkinIos.handleSize.width
                      : 36,
                  height: visuals.isIos
                      ? SoloForteSheetSkinIos.handleSize.height
                      : 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: visuals.isIos
                        ? SoloForteSheetSkinIos.handleColor
                        : const Color(0xFFC5C5C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: visuals.titleColor,
              ),
            ),
            if (contextLine != null && contextLine!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                contextLine!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: visuals.muted),
              ),
            ],
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 13, color: visuals.muted),
              ),
            ],
            if (banner != null) ...[
              const SizedBox(height: 12),
              banner!,
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Banner suave de sucesso/feedback dentro do sheet (substitui SnackBar pós-ação).
class ClientSheetInlineBanner extends StatelessWidget {
  const ClientSheetInlineBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: visuals.cardBg,
        borderRadius: BorderRadius.circular(visuals.inputRadius),
        border: Border.all(color: visuals.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: visuals.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: visuals.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card agrupado com rows de ação estilo iOS.
class ClientSheetActionCard extends StatelessWidget {
  const ClientSheetActionCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.cardBg,
        borderRadius: BorderRadius.circular(visuals.cardRadius),
        border: Border.all(color: visuals.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class ClientSheetActionRow extends StatelessWidget {
  const ClientSheetActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: visuals.isIos
                          ? SoloForteSheetSkinIos.iconBackground
                          : visuals.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        visuals.isIos
                            ? SoloForteSheetSkinIos.iconRadius
                            : 12,
                      ),
                    ),
                    child: Icon(icon, color: visuals.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: visuals.titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: visuals.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: visuals.arrowColor, size: 18),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 60,
            color: visuals.dividerColor,
          ),
      ],
    );
  }
}

class ClientSheetSectionLabel extends StatelessWidget {
  const ClientSheetSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: visuals.titleColor,
        ),
      ),
    );
  }
}

class ClientSheetFormField extends StatelessWidget {
  const ClientSheetFormField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.autofocus = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);

    final field = TextFormField(
      controller: controller,
      autofocus: autofocus,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: TextStyle(color: visuals.inputText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: visuals.inputHint),
        filled: true,
        fillColor: visuals.inputFill,
        contentPadding: SoloForteSheetTokens.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(visuals.inputRadius),
          borderSide: BorderSide(color: visuals.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(visuals.inputRadius),
          borderSide: BorderSide(color: visuals.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(visuals.inputRadius),
          borderSide: BorderSide(color: visuals.accent, width: 1.5),
        ),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSheetSectionLabel(label: label!),
        field,
      ],
    );
  }
}

class ClientSheetButtonRow extends StatelessWidget {
  const ClientSheetButtonRow({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    this.isSaving = false,
    this.confirmEnabled = true,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final bool isSaving;
  final bool confirmEnabled;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    final enabled = confirmEnabled && !isSaving;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: visuals.ghostText,
              side: BorderSide(color: visuals.ghostBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visuals.ghostRadius),
              ),
            ),
            onPressed: isSaving ? null : onCancel,
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: visuals.ctaBg,
              foregroundColor: visuals.ctaFg,
              disabledBackgroundColor: visuals.ctaBg.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visuals.ctaRadius),
              ),
            ),
            onPressed: enabled ? onConfirm : null,
            child: isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: visuals.ctaFg,
                    ),
                  )
                : Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}

class ClientSheetPrimaryButton extends StatelessWidget {
  const ClientSheetPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSaving = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: visuals.ctaBg,
          foregroundColor: visuals.ctaFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(visuals.ctaRadius),
          ),
        ),
        onPressed: isSaving ? null : onPressed,
        child: isSaving
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: visuals.ctaFg,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class ClientSheetFarmSkeleton extends StatelessWidget {
  const ClientSheetFarmSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final visuals = ClientSheetVisuals.of(context);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: visuals.inputFill,
        borderRadius: BorderRadius.circular(visuals.inputRadius),
        border: Border.all(color: visuals.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 10,
            width: 120,
            decoration: BoxDecoration(
              color: visuals.muted.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 180,
            decoration: BoxDecoration(
              color: visuals.muted.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Radio circular estilo iOS (22px) — não usa ícones Material.
class ClientSheetIosRadio extends StatelessWidget {
  const ClientSheetIosRadio({
    super.key,
    required this.selected,
    required this.accentColor,
    required this.mutedColor,
  });

  final bool selected;
  final Color accentColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? accentColor : mutedColor,
            width: 2,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
