import 'package:flutter/material.dart';
import '../../theme/soloforte_theme.dart';

class DemoModeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const DemoModeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: SoloRadius.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: SoloForteColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(
                  color: SoloForteColors.border,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Modo Demo (testar app)',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: SoloForteColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
