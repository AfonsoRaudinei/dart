import 'package:flutter/material.dart';
import '../../theme/soloforte_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    // Coleta do tema atual
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final primaryColor = SoloForteColors.primary; // Verde
    final secondaryColor = SoloForteColors.textSecondary;
    final tertiaryColor = SoloForteColors.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label externa (Design System: Label discreta 12-13px)
        Text(
          widget.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: _hasError ? errorColor : secondaryColor,
            fontWeight: SoloFontWeights.medium,
          ),
        ),
        const SizedBox(height: 8), // Spacing: 8px (SoloSpacing.xs)
        // Campo de Texto
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          style: theme.textTheme.bodyLarge, // Texto do input
          // Decoração (Herda a maior parte do InputDecorationTheme)
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: tertiaryColor, // Placeholder cinza
            ),

            // Ícone Prefix (Integrado)
            prefixIcon: Icon(
              widget.icon,
              color: _hasError
                  ? errorColor
                  : primaryColor, // Ícone Verde ou Vermelho
              size: 20, // Solo Icon Size Standard (20px em inputs)
            ),

            // Ícone Suffix (Senha)
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

            // Bordas e Fill são gerenciados pelo Theme, apenas ajustamos cores de erro/foco específicas aqui se necessário
            // O Theme define Radius 16 e Padding 16.
          ),

          validator: (value) {
            final error = widget.validator?.call(value);
            final hasErrorNow = error != null;
            if (_hasError != hasErrorNow) {
              setState(() {
                _hasError = hasErrorNow;
              });
            }
            return error;
          },
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
        ),
      ],
    );
  }
}
