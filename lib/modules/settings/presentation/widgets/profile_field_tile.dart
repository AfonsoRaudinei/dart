// ADR-032 — settings/presentation/widgets/profile_field_tile.dart
//
// Widget para exibir um campo do perfil com label, valor e ícone de edição.
// Campos somente leitura: onTap = null, ícone de edição não aparece.

import 'package:flutter/material.dart';

class ProfileFieldTile extends StatelessWidget {
  final String label;
  final String? value;
  final bool editable;
  final VoidCallback? onTap;

  const ProfileFieldTile({
    super.key,
    required this.label,
    this.value,
    this.editable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1D1D1F);
    const hintColor = Color(0xFF8E8E93);
    final displayValue = (value?.isNotEmpty == true) ? value! : '—';

    return InkWell(
      onTap: editable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  color: hintColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayValue,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                ),
              ),
            ),
            if (editable)
              const Icon(
                Icons.chevron_right,
                color: hintColor,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
