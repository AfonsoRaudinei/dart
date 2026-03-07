import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bloco de Conclusão Técnica — fundo #0057FF
/// Apenas 1 por case
class ConclusaoBlocoWidget extends StatelessWidget {
  final TextEditingController conclusaoCtrl;
  final VoidCallback onRemove;

  const ConclusaoBlocoWidget({
    super.key,
    required this.conclusaoCtrl,
    required this.onRemove,
  });

  static const Color _blueConc = Color(0xFF0057FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _blueConc.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _blueConc.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: _blueConc,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.notes_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Conclusão Técnica',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRemove();
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // ── Textarea ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: conclusaoCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText:
                    'Escreva sua conclusão técnica sobre o resultado do produto neste talhão...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: _blueConc.withValues(alpha: 0.5),
                  height: 1.5,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _blueConc.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _blueConc.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _blueConc, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
