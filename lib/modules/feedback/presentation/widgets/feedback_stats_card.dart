import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

class FeedbackStatsCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const FeedbackStatsCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: SoloTextStyles.headingLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: SoloTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
