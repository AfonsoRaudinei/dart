import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

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
      borderRadius: BorderRadius.circular(12),
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
                activeColor: const Color(0xFF34C759),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: context.premiumHairline,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Modo Demo (testar app)',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: context.premiumTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
