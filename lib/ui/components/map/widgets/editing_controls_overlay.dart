import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

class EditingControlsOverlay extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onUndo;
  final VoidCallback? onRedo;

  /// Controla habilitação visual dos botões Undo/Redo.
  final bool canUndo;
  final bool canRedo;

  const EditingControlsOverlay({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.onUndo,
    this.onRedo,
    this.canUndo = true,
    this.canRedo = false,
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
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Undo ─────────────────────────────────────────────
                Opacity(
                  opacity: canUndo ? 1.0 : 0.35,
                  child: IconButton(
                    onPressed: canUndo
                        ? () {
                            HapticFeedback.lightImpact();
                            onUndo();
                          }
                        : null,
                    icon: const Icon(Icons.undo_rounded),
                    tooltip: 'Desfazer',
                    color: Colors.black87,
                  ),
                ),
                // ── Redo ─────────────────────────────────────────────
                Opacity(
                  opacity: canRedo ? 1.0 : 0.35,
                  child: IconButton(
                    onPressed: canRedo && onRedo != null
                        ? () {
                            HapticFeedback.lightImpact();
                            onRedo!();
                          }
                        : null,
                    icon: const Icon(Icons.redo_rounded),
                    tooltip: 'Refazer',
                    color: Colors.black87,
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.withValues(alpha: 0.4),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onCancel();
                  },
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('Cancelar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onSave();
                  },
                  icon: const Icon(Icons.check, size: 20, color: Colors.white),
                  label: const Text(
                    'Salvar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTokens.brandGreen,
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
