import 'package:flutter/material.dart';

/// Widget de fallback quando módulo Drawing está desabilitado.
///
/// Exibido quando feature flag `drawing_v1` está desabilitada.
/// Não impacta navegação ou estado do mapa.

class DrawingDisabledWidget extends StatelessWidget {
  const DrawingDisabledWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Ícone
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),

          const SizedBox(height: 16),

          // Título
          Text(
            'Funcionalidade Indisponível',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),

          const SizedBox(height: 8),

          // Mensagem
          Text(
            'O módulo de desenho está temporariamente desabilitado.\n'
            'Entre em contato com o suporte se precisar desta funcionalidade.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 24),

          // Botão OK
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}
