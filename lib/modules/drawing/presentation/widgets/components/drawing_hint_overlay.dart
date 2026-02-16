import 'package:flutter/material.dart';
import '../../controllers/drawing_controller.dart';

/// Widget flutuante que exibe dicas contextuais durante o desenho.
/// 
/// Aparece no topo da tela mostrando:
/// - Instrução atual (ex: "Toque no mapa para iniciar")
/// - Métricas em tempo real (área, perímetro)
/// - Estado de validação (erros, avisos)
/// 
/// ⚠️ Este widget deve ser usado em um Overlay para flutuar sobre o mapa.
class DrawingHintOverlay extends StatelessWidget {
  final DrawingController controller;

  const DrawingHintOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // Só mostra se houver geometria ativa ou instrução importante
        final hasLiveGeometry = controller.liveGeometry != null;
        final hasError = controller.errorMessage != null;
        final isDrawing = controller.currentState.index > 1; // Não idle

        if (!hasLiveGeometry && !hasError && !isDrawing) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instrução
                    Row(
                      children: [
                        Icon(
                          _getInstructionIcon(),
                          size: 20,
                          color: _getInstructionColor(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.instructionText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _getInstructionColor(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Métricas (só se houver geometria)
                    if (hasLiveGeometry) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricChip(
                              icon: Icons.crop_square,
                              label: 'Área',
                              value: '${controller.liveAreaHa.toStringAsFixed(2)} ha',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricChip(
                              icon: Icons.straighten,
                              label: 'Perímetro',
                              value: '${controller.livePerimeterKm.toStringAsFixed(2)} km',
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Botão de cancelar (se estiver desenhando)
                    if (isDrawing && !hasError) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            controller.cancelOperation();
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getInstructionIcon() {
    if (controller.errorMessage != null) return Icons.error;
    return Icons.info;
  }

  Color _getInstructionColor() {
    if (controller.errorMessage != null) return Colors.red;
    return Colors.black87;
  }
}

/// Chip de métrica individual.
class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
