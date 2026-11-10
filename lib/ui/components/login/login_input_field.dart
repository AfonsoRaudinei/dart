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
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final primaryColor = context.themeAccent; // Verde
    final secondaryColor = context.premiumTextSecondary;
    final tertiaryColor = context.premiumTextTertiary;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: _hasError ? errorColor : secondaryColor,
            fontWeight: FontWeight.w500,
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
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: tertiaryColor,
              ),
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
