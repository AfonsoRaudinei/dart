import 'package:flutter/material.dart';
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
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.campaign_rounded, size: 20),
      label: Text(isLoading ? 'Publicando...' : 'Publicar Case'),
      style: ElevatedButton.styleFrom(
        backgroundColor: PremiumTokens.brandGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
