// lib/core/ui/sheets/widgets/sheet_input_field.dart

import 'package:flutter/material.dart';
import '../sheet_tokens.dart';

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
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: SoloForteSheetTokens.inputText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: SoloForteSheetTokens.inputHint),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: SoloForteSheetTokens.inputBackground,
        contentPadding: SoloForteSheetTokens.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloForteSheetTokens.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloForteSheetTokens.inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SoloForteSheetTokens.inputRadius),
          borderSide: const BorderSide(
            color: SoloForteSheetTokens.chipBorderActive,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
