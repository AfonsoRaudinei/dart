// lib/core/ui/sheets/widgets/sheet_input_field.dart

import 'package:flutter/material.dart';
import '../sheet_tokens.dart';
import '../solo_forte_sheet_visuals.dart';

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
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final showInputBorder = v.isIos || v.isLight;

    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: TextStyle(color: v.inputText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: v.inputHint),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: v.inputFill,
        contentPadding: SoloForteSheetTokens.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(v.inputRadius),
          borderSide: showInputBorder
              ? BorderSide(color: v.inputBorder)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(v.inputRadius),
          borderSide: showInputBorder
              ? BorderSide(color: v.inputBorder)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(v.inputRadius),
          borderSide: BorderSide(color: v.focusBorder, width: 1.5),
        ),
      ),
    );
  }
}
