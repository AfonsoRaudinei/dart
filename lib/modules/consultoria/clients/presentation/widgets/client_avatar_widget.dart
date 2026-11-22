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

  /// Paleta curada (tons de lavoura, solo e céu), todos com contraste AA
  /// para a letra branca. Mesma paleta para todo o app: reconhecimento rápido.
  static const List<Color> palette = [
    Color(0xFF2F7D4F), // verde lavoura
    Color(0xFF1F6F8B), // azul céu
    Color(0xFFB45309), // âmbar (grão maduro)
    Color(0xFF7A4E2D), // solo
    Color(0xFF4D7C0F), // verde folha
    Color(0xFF0F766E), // teal
    Color(0xFF9A3412), // terracota
    Color(0xFF475569), // ardósia
  ];

  /// Cor determinística por nome. Usa soma estável dos code units, pois
  /// `String.hashCode` não é garantido entre execuções.
  static Color colorFor(String nome) {
    final key = nome.trim().toLowerCase();
    var sum = 0;
    for (final unit in key.codeUnits) {
      sum = (sum * 31 + unit) & 0x7fffffff;
    }
    return palette[sum % palette.length];
  }

  Color get _backgroundColor => colorFor(nome);

  String get _initial => nome.isNotEmpty ? nome[0].toUpperCase() : '?';

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
