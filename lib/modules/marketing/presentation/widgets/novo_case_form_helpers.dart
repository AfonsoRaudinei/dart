import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

/// Helpers compartilhados pelas seções do NovoCaseSheet.
/// Funções top-level e widget auxiliar — sem estado, sem providers.

Widget novoCaseSectionLabel(String label) {
  return Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: SoloForteSheetTokens.sectionLabel,
      fontWeight: SoloForteSheetTokens.sectionWeight,
      fontSize: SoloForteSheetTokens.sectionFontSize,
    ),
  );
}

Widget novoCaseFieldBox({required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: SoloForteSheetTokens.inputBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: PremiumTokens.hairlineLight),
    ),
    child: child,
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
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    onChanged: onChanged,
    style: const TextStyle(color: SoloForteSheetTokens.inputText),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: SoloForteSheetTokens.inputHint,
        fontSize: 14,
      ),
      filled: true,
      fillColor: SoloForteSheetTokens.inputBackground,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      isDense: true,
    ),
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
        : null,
  );
}

/// Divisor interno entre campos de um fieldBox.
class NovoCaseFDivider extends StatelessWidget {
  const NovoCaseFDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0.5,
      thickness: 0.5,
      color: PremiumTokens.hairlineLight,
    );
  }
}
