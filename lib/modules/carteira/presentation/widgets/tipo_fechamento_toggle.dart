import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/entities/carteira_lancamento.dart';

/// Toggle entre [Vendido] e [Perdido para concorrência].
class TipoFechamentoToggle extends StatelessWidget {
  const TipoFechamentoToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.obrigatorio = false,
    this.erro,
  });

  final TipoFechamento? value;
  final ValueChanged<TipoFechamento?> onChanged;
  final bool obrigatorio;
  final String? erro;

  void _select(TipoFechamento tipo) {
    HapticFeedback.selectionClick();
    if (obrigatorio) {
      onChanged(tipo);
      return;
    }
    onChanged(value == tipo ? null : tipo);
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).hintColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF242426)
        : const Color(0xFFE5E5EA);
    final selectedFill = isDark ? context.premiumSurface : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          obrigatorio ? 'Tipo de fechamento *' : 'Tipo de fechamento (opcional)',
          style: TextStyle(fontSize: 12, color: hintColor),
        ),
        const SizedBox(height: 6),
        Container(
          height: 34,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              _ToggleSide(
                label: 'Vendido',
                isSelected: value == TipoFechamento.vendido,
                selectedFill: selectedFill,
                onTap: () => _select(TipoFechamento.vendido),
              ),
              _ToggleSide(
                label: 'Perdido p/ conc.',
                isSelected: value == TipoFechamento.perdido,
                selectedFill: selectedFill,
                onTap: () => _select(TipoFechamento.perdido),
              ),
            ],
          ),
        ),
        if (!obrigatorio && value == null) ...[
          const SizedBox(height: 4),
          Text(
            'Negociação em aberto',
            style: TextStyle(fontSize: 11, color: hintColor),
          ),
        ],
        if (erro != null) ...[
          const SizedBox(height: 4),
          Text(
            erro!,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.error,
            ),
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
    required this.selectedFill,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color selectedFill;
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
            color: isSelected ? selectedFill : Colors.transparent,
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
