// lib/modules/agenda/widgets/efficiency_badge.dart
import 'package:flutter/material.dart';

class EfficiencyBadge extends StatelessWidget {
  final double efficiency;
  
  const EfficiencyBadge({
    super.key,
    required this.efficiency,
  });

  Color get _color {
    if (efficiency >= 80) return Colors.green;
    if (efficiency >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 20, color: _color),
          SizedBox(width: 8),
          Text(
            '${efficiency.toStringAsFixed(0)}%',
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
