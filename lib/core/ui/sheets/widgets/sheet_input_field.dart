// lib/core/ui/sheets/widgets/sheet_input_field.dart

import 'package:flutter/material.dart';
import '../sheet_tokens.dart';
import '../soloforte_sheet.dart';

class SheetInputField extends StatelessWidget {
  const SheetInputField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final textColor =
        isIos ? SoloForteSheetSkinIos.titleColor : SoloForteSheetTokens.inputText;
    final hintColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : SoloForteSheetTokens.inputHint;
    final fillColor = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final focusBorder = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : SoloForteSheetTokens.chipBorderActive;
    final radius = isIos
        ? SoloForteSheetSkinIos.cardRadius
        : SoloForteSheetTokens.inputRadius;

    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding: SoloForteSheetTokens.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: isIos
              ? const BorderSide(color: SoloForteSheetSkinIos.cardBorder)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: isIos
              ? const BorderSide(color: SoloForteSheetSkinIos.cardBorder)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: focusBorder, width: 1.5),
        ),
      ),
    );
  }
}
