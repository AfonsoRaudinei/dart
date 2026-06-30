import 'package:flutter/material.dart';

class ConflictResolutionDialog extends StatelessWidget {
  final String title;
  final String description;
  final Widget? localPreview;
  final Widget? remotePreview;
  final VoidCallback onUseLocal;
  final VoidCallback onUseRemote;

  const ConflictResolutionDialog({
    super.key,
    required this.title,
    required this.description,
    this.localPreview,
    this.remotePreview,
    required this.onUseLocal,
    required this.onUseRemote,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.sync_problem, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _OptionCard(
                    title: 'Versão Local',
                    preview: localPreview,
                    onTap: () {
                      onUseLocal();
                      Navigator.of(context).pop();
                    },
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionCard(
                    title: 'Versão Remota',
                    preview: remotePreview,
                    onTap: () {
                      onUseRemote();
                      Navigator.of(context).pop();
                    },
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Decidir depois',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final Widget? preview;
  final VoidCallback onTap;
  final Color color;

  const _OptionCard({
    required this.title,
    this.preview,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 12),
            if (preview != null) ...[
              preview!,
              const SizedBox(height: 12),
            ] else
              const Icon(
                Icons.description_outlined,
                size: 40,
                color: Colors.grey,
              ),

            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Usar esta', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
