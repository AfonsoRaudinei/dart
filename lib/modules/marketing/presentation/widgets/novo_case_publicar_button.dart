import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
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
    final isIos = soloForteSheetIsIos(context);
    final bg =
        isIos ? SoloForteSheetSkinIos.ctaBackground : PremiumTokens.brandGreen;
    final fg = isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final radius =
        isIos ? SoloForteSheetSkinIos.ctaRadius : 14.0;

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
