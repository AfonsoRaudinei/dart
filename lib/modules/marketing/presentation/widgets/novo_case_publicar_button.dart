import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

/// Botão de publicar extraído do NovoCaseSheet.
class NovoCasePublicarButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const NovoCasePublicarButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
        final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final bg =
        isIos ? v.ctaBackground : context.themeAccent;
    final fg = v.ctaText;
    final radius =
        v.ctaRadius;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg,
              ),
            )
          : const Icon(Icons.campaign_rounded, size: 20),
      label: Text(isLoading ? 'Publicando...' : 'Publicar Case'),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
