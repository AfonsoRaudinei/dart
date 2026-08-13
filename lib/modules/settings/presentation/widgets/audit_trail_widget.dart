// ADR-032 — settings/presentation/widgets/audit_trail_widget.dart
//
// Exibe lista cronológica reversa das últimas alterações no perfil.
// Append-only — nunca mostra operações de deleção.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../data/models/user_profile_audit_entry.dart';

class AuditTrailWidget extends StatelessWidget {
  final List<UserProfileAuditEntry> entries;

  const AuditTrailWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          'Nenhuma alteração registrada',
          style: TextStyle(
            color: context.premiumTextSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: context.premiumHairline,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final dateStr =
            DateFormat('dd/MM/yyyy HH:mm').format(entry.changedAt.toLocal());
        final oldVal =
            (entry.oldValue?.isNotEmpty == true) ? '"${entry.oldValue}"' : '—';
        final newVal = '"${entry.newValue}"';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[$dateStr]  ${entry.fieldChanged}',
                style: TextStyle(
                  color: context.premiumTextSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$oldVal → $newVal',
                style: TextStyle(
                  color: context.premiumTextPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
