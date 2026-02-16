/*
════════════════════════════════════════════════════════════════════
DRAWING STATE INDICATOR — SOLOFORTE
════════════════════════════════════════════════════════════════════

Widget que exibe feedback visual do estado atual do desenho.
Mostra ao usuário em que modo ele está e o que pode fazer.

CARACTERÍSTICAS:
- Posicionado no topo do mapa
- Animações suaves de transição
- Cores específicas por estado
- Ícones descritivos
- Mensagens claras
════════════════════════════════════════════════════════════════════
*/

import 'package:flutter/material.dart';
import '../../domain/drawing_state.dart';

class DrawingStateIndicator extends StatelessWidget {
  final DrawingState state;
  final DrawingTool tool;

  const DrawingStateIndicator({
    super.key,
    required this.state,
    required this.tool,
  });

  @override
  Widget build(BuildContext context) {
    // Não exibir se estiver em idle
    if (state == DrawingState.idle) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _colorForState(state),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForState(state, tool), size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            _messageForState(state),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna a cor de fundo baseada no estado
  Color _colorForState(DrawingState state) {
    switch (state) {
      case DrawingState.idle:
        return Colors.grey.shade600;
      case DrawingState.armed:
        return Colors.orange.shade600;
      case DrawingState.drawing:
        return Colors.blue.shade600;
      case DrawingState.reviewing:
        return Colors.green.shade600;
      case DrawingState.editing:
        return Colors.purple.shade600;
      case DrawingState.importPreview:
        return Colors.indigo.shade600;
      case DrawingState.booleanOperation:
        return Colors.amber.shade700;
    }
  }

  /// Retorna o ícone baseado no estado e ferramenta
  IconData _iconForState(DrawingState state, DrawingTool tool) {
    switch (state) {
      case DrawingState.idle:
        return Icons.touch_app;
      case DrawingState.armed:
        return _iconForTool(tool);
      case DrawingState.drawing:
        return Icons.edit_location;
      case DrawingState.reviewing:
        return Icons.check_circle_outline;
      case DrawingState.editing:
        return Icons.edit;
      case DrawingState.importPreview:
        return Icons.visibility;
      case DrawingState.booleanOperation:
        return Icons.merge_type;
    }
  }

  /// Retorna o ícone específico da ferramenta
  IconData _iconForTool(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.polygon:
        return Icons.hexagon_outlined;
      case DrawingTool.freehand:
        return Icons.gesture;
      case DrawingTool.pivot:
        return Icons.radio_button_checked;
      case DrawingTool.rectangle:
        return Icons.rectangle_outlined;
      case DrawingTool.circle:
        return Icons.circle_outlined;
      case DrawingTool.none:
        return Icons.my_location;
    }
  }

  /// Retorna a mensagem descritiva do estado
  String _messageForState(DrawingState state) {
    switch (state) {
      case DrawingState.idle:
        return 'Toque no mapa para navegar';
      case DrawingState.armed:
        return 'Toque para iniciar desenho';
      case DrawingState.drawing:
        return 'Desenhando... (toque duplo para finalizar)';
      case DrawingState.reviewing:
        return 'Revisar e confirmar';
      case DrawingState.editing:
        return 'Editando vértices';
      case DrawingState.importPreview:
        return 'Visualizando importação';
      case DrawingState.booleanOperation:
        return 'Operação booleana em andamento';
    }
  }
}

/// Widget wrapper que posiciona o indicador no topo do mapa
class DrawingStateOverlay extends StatelessWidget {
  final DrawingState state;
  final DrawingTool tool;
  final Widget child;

  const DrawingStateOverlay({
    super.key,
    required this.state,
    required this.tool,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Indicador no topo
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: DrawingStateIndicator(state: state, tool: tool),
          ),
        ),
      ],
    );
  }
}

/// Badge menor para exibir ao lado de ferramentas
class DrawingStateBadge extends StatelessWidget {
  final DrawingState state;

  const DrawingStateBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == DrawingState.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _colorForState(state),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _labelForState(state),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _colorForState(DrawingState state) {
    switch (state) {
      case DrawingState.armed:
        return Colors.orange;
      case DrawingState.drawing:
        return Colors.blue;
      case DrawingState.reviewing:
        return Colors.green;
      case DrawingState.editing:
        return Colors.purple;
      case DrawingState.importPreview:
        return Colors.indigo;
      case DrawingState.booleanOperation:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _labelForState(DrawingState state) {
    switch (state) {
      case DrawingState.armed:
        return 'ARMADO';
      case DrawingState.drawing:
        return 'DESENHANDO';
      case DrawingState.reviewing:
        return 'REVISÃO';
      case DrawingState.editing:
        return 'EDITANDO';
      case DrawingState.importPreview:
        return 'VISUALIZANDO';
      case DrawingState.booleanOperation:
        return 'OPERAÇÃO';
      default:
        return '';
    }
  }
}
