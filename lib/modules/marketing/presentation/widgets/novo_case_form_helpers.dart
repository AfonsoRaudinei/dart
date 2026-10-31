import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

/// Helpers compartilhados pelas seções do NovoCaseSheet.
/// Funções top-level e widget auxiliar — sem estado, sem providers.

Color novoCasePrimaryTextColor(BuildContext context) {
  return soloForteSheetIsIos(context)
      ? SoloForteSheetSkinIos.titleColor
      : SoloForteSheetTokens.inputText;
}

Color novoCaseSecondaryTextColor(BuildContext context) {
  return soloForteSheetIsIos(context)
      ? SoloForteSheetSkinIos.subtitleColor
      : SoloForteSheetTokens.inputHint;
}

Color novoCaseAccentColor(BuildContext context) {
  return soloForteSheetIsIos(context)
      ? SoloForteSheetSkinIos.iconStroke
      : context.themeAccent;
}

BoxDecoration novoCaseInnerCardDecoration(
  BuildContext context, {
  bool selected = false,
}) {
  final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
  if (isIos) {
    return BoxDecoration(
      color: SoloForteSheetSkinIos.cardBackground,
      borderRadius: BorderRadius.circular(SoloForteSheetSkinIos.cardRadius),
      border: Border.all(
        color: selected
            ? SoloForteSheetSkinIos.iconStroke
            : SoloForteSheetSkinIos.cardBorder,
      ),
      boxShadow: selected
          ? const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                offset: Offset(0, 10),
                blurRadius: 28,
              ),
            ]
          : null,
    );
  }
  return BoxDecoration(
    color: SoloForteSheetTokens.inputBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: selected
          ? context.themeAccent
          : PremiumTokens.hairlineLight,
    ),
    boxShadow: selected
        ? const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              offset: Offset(0, 10),
              blurRadius: 28,
            ),
          ]
        : null,
  );
}

ButtonStyle novoCaseGhostOutlinedButtonStyle(BuildContext context) {
  final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
  return OutlinedButton.styleFrom(
    foregroundColor: isIos
        ? SoloForteSheetSkinIos.ghostText
        : SoloForteSheetTokens.inputText,
    side: BorderSide(
      color: isIos
          ? SoloForteSheetSkinIos.ghostBorder
          : PremiumTokens.hairlineLight,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        isIos ? SoloForteSheetSkinIos.ghostRadius : 16,
      ),
    ),
    minimumSize: const Size.fromHeight(48),
  );
}

Widget novoCaseSectionLabel(String label) {
  return Builder(
    builder: (context) {
      final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
      return Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isIos
              ? SoloForteSheetSkinIos.titleColor
              : SoloForteSheetTokens.sectionLabel,
          fontWeight: SoloForteSheetTokens.sectionWeight,
          fontSize: SoloForteSheetTokens.sectionFontSize,
        ),
      );
    },
  );
}

Widget novoCaseFieldBox({required Widget child}) {
  return Builder(
    builder: (context) {
      final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isIos
              ? SoloForteSheetSkinIos.cardBackground
              : SoloForteSheetTokens.inputBackground,
          borderRadius: BorderRadius.circular(
            isIos ? SoloForteSheetSkinIos.cardRadius : 14,
          ),
          border: Border.all(
            color: isIos
                ? SoloForteSheetSkinIos.cardBorder
                : PremiumTokens.hairlineLight,
          ),
        ),
        child: child,
      );
    },
  );
}

Widget novoCaseTextInput(
  TextEditingController controller,
  String hint, {
  TextInputType keyboardType = TextInputType.text,
  bool required = false,
  int maxLines = 1,
  void Function(String)? onChanged,
}) {
  return Builder(
    builder: (context) {
      final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
      final textColor = isIos
          ? SoloForteSheetSkinIos.titleColor
          : SoloForteSheetTokens.inputText;
      final hintColor = isIos
          ? SoloForteSheetSkinIos.subtitleColor
          : SoloForteSheetTokens.inputHint;
      // Um único card: o chrome vem de [novoCaseFieldBox]. Sem fill/borda
      // do InputDecorationTheme (OutlineInputBorder) — evita quadro-no-card.
      final fill = isIos
          ? Colors.transparent
          : SoloForteSheetTokens.inputBackground;

      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14,
          ),
          filled: true,
          fillColor: fill,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
            : null,
      );
    },
  );
}

/// Divisor interno entre campos de um fieldBox.
class NovoCaseFDivider extends StatelessWidget {
  const NovoCaseFDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final v = SoloForteSheetVisuals.of(context);
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: isIos
          ? SoloForteSheetSkinIos.rowDivider
          : PremiumTokens.hairlineLight,
    );
  }
}
