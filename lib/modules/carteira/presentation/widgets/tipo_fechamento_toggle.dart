import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/carteira_lancamento.dart';

/// Toggle compacto e opcional entre [Vendido] e [Perdido para concorrência].
///
/// Toque no rótulo ativo novamente para limpar a seleção (negociação em aberto).
class TipoFechamentoToggle extends StatelessWidget {
  const TipoFechamentoToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TipoFechamento? value;
  final ValueChanged<TipoFechamento?> onChanged;

  void _select(TipoFechamento tipo) {
    HapticFeedback.selectionClick();
    onChanged(value == tipo ? null : tipo);
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tipo de fechamento (opcional)',
          style: TextStyle(fontSize: 12, color: hintColor),
        ),
        const SizedBox(height: 6),
        Container(
          height: 34,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              _ToggleSide(
                label: 'Vendido',
                isSelected: value == TipoFechamento.vendido,
                onTap: () => _select(TipoFechamento.vendido),
              ),
              _ToggleSide(
                label: 'Perdido p/ conc.',
                isSelected: value == TipoFechamento.perdido,
                onTap: () => _select(TipoFechamento.perdido),
              ),
            ],
          ),
        ),
        if (value == null) ...[
          const SizedBox(height: 4),
          Text(
            'Negociação em aberto',
            style: TextStyle(fontSize: 11, color: hintColor),
          ),
        ],
      ],
    );
  }
}

class _ToggleSide extends StatelessWidget {
  const _ToggleSide({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).hintColor,
            ),
          ),
        ),
      ),
    );
  }
}
