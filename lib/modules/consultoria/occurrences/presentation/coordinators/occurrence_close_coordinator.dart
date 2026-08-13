import 'package:flutter/material.dart';

import 'occurrence_form_guard.dart';

/// Confirma descarte de rascunho antes de fechar o formulário de ocorrência.
class OccurrenceCloseCoordinator {
  const OccurrenceCloseCoordinator._();

  /// Retorna `true` quando o host pode fechar o sheet.
  static Future<bool> confirmDiscardIfDirty(
    BuildContext context, {
    OccurrenceFormGuard? guard,
  }) async {
    if (guard == null || !guard.isDirty) return true;
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar ocorrência?'),
        content: const Text(
          'Existem dados preenchidos que ainda não foram salvos. '
          'Deseja descartar e fechar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuar preenchendo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
