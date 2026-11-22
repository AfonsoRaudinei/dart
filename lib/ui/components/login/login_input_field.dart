import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

class LoginInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon; // Prefix icon
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
    required this.label, // Label externa (Visual Label)
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

  void _scheduleErrorStateUpdate(bool hasErrorNow) {
    if (_hasError == hasErrorNow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_hasError != hasErrorNow) {
        setState(() => _hasError = hasErrorNow);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // O painel de login é sempre claro (vidro branco sobre a foto), então os
    // campos têm paleta própria e não herdam o tema escuro do app.
    const errorColor = Color(0xFFD70015);
    const primaryColor = PremiumTokens.brandGreenAccessible;
    const secondaryColor = Color(0xFF55555A);
    const hintColor = Color(0xFF6C6C70);
    const fillColor = Color(0xFFF2F2F7);
    const borderColor = Color(0xFFD1D1D6);
    const textColor = Color(0xFF1C1C1E);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: _hasError ? errorColor : secondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: widget.label,
          textField: true,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            scrollPadding: EdgeInsets.only(bottom: keyboardInset + 120),
            style: const TextStyle(fontSize: 16, color: textColor),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(fontSize: 15, color: hintColor),
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              border: outline(borderColor),
              enabledBorder: outline(borderColor),
              focusedBorder: outline(primaryColor, 1.8),
              errorBorder: outline(errorColor),
              focusedErrorBorder: outline(errorColor, 1.8),
              errorStyle: const TextStyle(color: errorColor, fontSize: 12),
              prefixIcon: Icon(
                widget.icon,
                color: _hasError ? errorColor : primaryColor,
                size: 20,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: secondaryColor,
                        size: 20,
                      ),
                      onPressed: _togglePasswordVisibility,
                    )
                  : null,
            ),
            validator: (value) {
              final error = widget.validator?.call(value);
              _scheduleErrorStateUpdate(error != null);
              return error;
            },
            onChanged: (value) {
              if (_hasError) {
                final error = widget.validator?.call(value);
                _scheduleErrorStateUpdate(error != null);
              }
              widget.onChanged?.call(value);
            },
            onFieldSubmitted: widget.onSubmitted,
          ),
        ),
      ],
    );
  }
}
