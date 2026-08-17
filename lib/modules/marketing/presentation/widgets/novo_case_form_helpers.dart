import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

/// Helpers compartilhados pelas seções do NovoCaseSheet.
/// Funções top-level e widget auxiliar — sem estado, sem providers.

Widget novoCaseSectionLabel(String label) {
  return Builder(
    builder: (context) {
      final isIos = soloForteSheetIsIos(context);
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
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: isIos
          ? SoloForteSheetSkinIos.rowDivider
          : PremiumTokens.hairlineLight,
    );
  }
}
