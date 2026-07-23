import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../ui/theme/premium/design_tokens.dart';

/// Avatar circular do cliente.
///
/// Exibe a foto local se [fotoPath] for válido; caso contrário,
/// exibe a letra inicial do [nome] com cor determinística.
class ClientAvatarWidget extends StatelessWidget {
  final String? fotoPath;
  final String nome;
  final double radius;

  const ClientAvatarWidget({
    super.key,
    this.fotoPath,
    required this.nome,
    this.radius = 28,
  });

  static const List<Color> _bgColors = [
    Color(0xFF2E7D32), // verde escuro
    Color(0xFF1565C0), // azul
    Color(0xFF6A1B9A), // roxo
    Color(0xFFBF360C), // laranja escuro
    Color(0xFF00695C), // teal
    Color(0xFF4527A0), // índigo
    Color(0xFF558B2F), // verde claro
    Color(0xFF37474F), // cinza azulado
  ];

  Color get _backgroundColor {
    final idx = nome.hashCode.abs() % _bgColors.length;
    return _bgColors[idx];
  }

  String get _initial =>
      nome.isNotEmpty ? nome[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    if (fotoPath != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: context.premiumBackground,
        child: ClipOval(
          child: SizedBox.square(
            dimension: radius * 2,
            child: Image.file(
              File(fotoPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitial(),
            ),
          ),
        ),
      );
    }
    return _buildInitial();
  }

  Widget _buildInitial() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _backgroundColor,
      child: Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
