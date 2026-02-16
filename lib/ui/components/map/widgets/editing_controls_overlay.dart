import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

class EditingControlsOverlay extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onUndo;

  const EditingControlsOverlay({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo),
                  tooltip: 'Desfazer',
                  color: Colors.black87,
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.withOpacity(0.4),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('Cancelar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check, size: 20, color: Colors.white),
                  label: const Text(
                    'Salvar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SoloForteColors.greenIOS,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
