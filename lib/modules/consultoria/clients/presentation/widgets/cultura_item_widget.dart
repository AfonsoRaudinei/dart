import 'package:flutter/material.dart';
import '../../domain/client_cultura.dart';

/// Item de lista para exibição (e opcionalmente remoção) de uma [ClientCultura].
///
/// Quando [onRemove] é null, opera em modo somente-leitura.
class CulturaItemWidget extends StatelessWidget {
  final ClientCultura cultura;
  final VoidCallback? onRemove;

  const CulturaItemWidget({
    super.key,
    required this.cultura,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final areaFormatted =
        cultura.areaHa % 1 == 0
            ? '${cultura.areaHa.toStringAsFixed(0)} ha'
            : '${cultura.areaHa.toStringAsFixed(1)} ha';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE8F5E9),
        child: Icon(Icons.eco, color: Color(0xFF2E7D32), size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              cultura.culturaTipo.label,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              areaFormatted,
              style: tt.labelSmall?.copyWith(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: cultura.variedade != null && cultura.variedade!.isNotEmpty
          ? Text(
              cultura.variedade!,
              style: tt.bodySmall?.copyWith(color: Colors.grey[600]),
            )
          : null,
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[400],
              onPressed: onRemove,
              tooltip: 'Remover cultura',
            )
          : null,
    );
  }
}
