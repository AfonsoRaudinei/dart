import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

/// Valor persistido em [MarketingCase.produtorFazenda]: texto manual ou fallback do cliente.
String marketingEffectiveProdutorFazenda({
  required String manualProdutor,
  required String? selectedClientName,
}) {
  final manual = manualProdutor.trim();
  if (manual.isNotEmpty) return manual;
  final clientName = selectedClientName?.trim() ?? '';
  return clientName;
}

/// Campo Produtor/Fazenda obrigatório somente sem cliente no dropdown.
bool marketingProdutorFieldRequired({required String? clientId}) {
  return clientId == null;
}

/// Pré-preenchimento da visita: evita duplicar só o nome do cliente no campo.
String marketingVisitInitialProdutorFieldText({
  required String? producerFarmLabel,
  required String? clientName,
}) {
  final label = producerFarmLabel?.trim() ?? '';
  if (label.isEmpty) return '';
  final client = clientName?.trim() ?? '';
  if (client.isNotEmpty && label == client) return '';
  return label;
}

/// Helpers compartilhados pelas seções do NovoCaseSheet.
/// Funções top-level e widget auxiliar — sem estado, sem providers.

Color novoCasePrimaryTextColor(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
  return soloForteSheetIsIos(context)
      ? v.titleColor
      : v.inputText;
}

Color novoCaseSecondaryTextColor(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
  return soloForteSheetIsIos(context)
      ? v.subtitleColor
      : v.inputHint;
}

Color novoCaseAccentColor(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
  return soloForteSheetIsIos(context)
      ? v.iconStroke
      : context.themeAccent;
}

BoxDecoration novoCaseInnerCardDecoration(
  BuildContext context, {
  bool selected = false,
}) {
    final v = SoloForteSheetVisuals.of(context);
  if (soloForteSheetIsIos(context)) {
    return BoxDecoration(
      color: v.cardBackground,
      borderRadius: BorderRadius.circular(v.cardRadius),
      border: Border.all(
        color: selected
            ? v.iconStroke
            : v.cardBorder,
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
    color: v.inputFill,
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
  final v = SoloForteSheetVisuals.of(context);
  return OutlinedButton.styleFrom(
    foregroundColor: v.ghostText,
    side: BorderSide(
      color: v.ghostBorder,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        v.isIos ? v.ghostRadius : 16,
      ),
    ),
    minimumSize: const Size.fromHeight(48),
  );
}

Widget novoCaseSectionLabel(String label) {
  return Builder(
    builder: (context) {
      final v = SoloForteSheetVisuals.of(context);
      return Text(
        label.toUpperCase(),
        style: TextStyle(
          color: v.titleColor,
          fontWeight: v.sectionWeight,
          fontSize: v.sectionFontSize,
        ),
      );
    },
  );
}

Widget novoCaseFieldBox({required Widget child}) {
  return Builder(
    builder: (context) {
      final v = SoloForteSheetVisuals.of(context);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: v.cardBackground,
          borderRadius: BorderRadius.circular(
            v.cardRadius,
          ),
          border: Border.all(
            color: v.cardBorder,
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
      final v = SoloForteSheetVisuals.of(context);
      final textColor = v.titleColor;
      final hintColor = v.subtitleColor;
      // Um único card: o chrome vem de [novoCaseFieldBox]. Sem fill/borda
      // do InputDecorationTheme (OutlineInputBorder) — evita quadro-no-card.
      final fill = v.isIos ? Colors.transparent : v.cardBackground;

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
    final v = SoloForteSheetVisuals.of(context);
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: v.dividerColor,
    );
  }
}
