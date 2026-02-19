import 'package:flutter/material.dart';
import '../../theme/soloforte_theme.dart';

class SocialAuthButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? borderColor;
  final Color? iconColor;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.borderColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: SoloForteColors.textPrimary,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(
          color: borderColor ?? SoloForteColors.border,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: SoloRadius.radiusMd),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? SoloForteColors.textPrimary, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: SoloForteColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
