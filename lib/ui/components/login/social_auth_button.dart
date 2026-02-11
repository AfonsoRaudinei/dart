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
        side: BorderSide(
          color: borderColor ?? SoloForteColors.border,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: SoloRadius.radiusLg),
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
              fontSize: 15.2,
              fontWeight: FontWeight.w500,
              color: SoloForteColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
