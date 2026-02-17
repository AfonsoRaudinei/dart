import 'package:flutter/material.dart';
import '../../../../../../ui/theme/soloforte_theme.dart';

class CameraActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const CameraActionButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: SoloForteColors.grayLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SoloForteColors.greenIOS.withValues(alpha: 0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: SoloForteColors.greenIOS,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Foto',
              style: TextStyle(
                fontSize: 10,
                color: SoloForteColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
