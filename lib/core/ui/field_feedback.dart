import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Confirmação de sucesso em linguagem de campo: vibração leve + aviso curto
/// com ícone. Reservado a marcos reais (visita concluída, talhão salvo),
/// para o destaque não virar ruído.
void showFieldSuccess(BuildContext context, String message) {
  HapticFeedback.mediumImpact();
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2600),
      backgroundColor: const Color(0xFF1F7A45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
