import 'package:flutter/material.dart';

/// Dialog de confirmação para alterações não salvas
class UnsavedChangesDialog extends StatelessWidget {
  final VoidCallback? onSaveAndExit;
  final VoidCallback onDiscardAndExit;
  final VoidCallback onCancel;

  const UnsavedChangesDialog({
    super.key,
    this.onSaveAndExit,
    required this.onDiscardAndExit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('Alterações não salvas'),
        ],
      ),
      content: const Text(
        'Você possui alterações não salvas nesta aba. Deseja sair sem salvar?',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
        if (onSaveAndExit != null)
          TextButton(
            onPressed: onSaveAndExit,
            child: const Text(
              'Salvar e Sair',
              style: TextStyle(
                color: Color(0xFF4ADE80),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        TextButton(
          onPressed: onDiscardAndExit,
          child: Text(
            'Sair sem Salvar',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Exibe o dialog e retorna true se pode trocar de view
  static Future<bool> show(BuildContext context, {VoidCallback? onSave}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnsavedChangesDialog(
        onSaveAndExit: onSave != null
            ? () {
                onSave();
                Navigator.of(context).pop(true);
              }
            : null,
        onDiscardAndExit: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    return result ?? false;
  }
}
