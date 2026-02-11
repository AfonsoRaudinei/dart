import 'package:flutter/material.dart';
import '../../theme/soloforte_theme.dart';

class LoginInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const LoginInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<LoginInputField> createState() => _LoginInputFieldState();
}

class _LoginInputFieldState extends State<LoginInputField> {
  bool _obscureText = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: SoloTextStyles.label.copyWith(
            color: _hasError
                ? SoloForteColors.error
                : SoloForteColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          style: SoloTextStyles.body,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: SoloForteColors.textTertiary,
              fontSize: SoloFontSizes.base,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _hasError
                  ? SoloForteColors.error
                  : SoloForteColors.blueSamsung,
              size: 20,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: SoloForteColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: _togglePasswordVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: SoloRadius.radiusMd,
              borderSide: BorderSide(
                color: _hasError
                    ? SoloForteColors.error
                    : SoloForteColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: SoloRadius.radiusMd,
              borderSide: BorderSide(
                color: _hasError
                    ? SoloForteColors.error
                    : SoloForteColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: SoloRadius.radiusMd,
              borderSide: BorderSide(
                color: _hasError
                    ? SoloForteColors.error
                    : SoloForteColors.blueSamsung,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: SoloRadius.radiusMd,
              borderSide: const BorderSide(color: SoloForteColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: SoloRadius.radiusMd,
              borderSide: const BorderSide(
                color: SoloForteColors.error,
                width: 2,
              ),
            ),
            contentPadding: SoloSpacing.paddingInput,
          ),
          validator: (value) {
            final error = widget.validator?.call(value);
            setState(() {
              _hasError = error != null;
            });
            return error;
          },
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
        ),
      ],
    );
  }
}
