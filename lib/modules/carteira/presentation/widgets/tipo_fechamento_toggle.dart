import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';

import '../../domain/entities/carteira_lancamento.dart';

/// Escolha entre [Vendido] e [Perdido para concorrência], em dois cartões.
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

  static const _verde = Color(0xFF16A34A);
  static const _vermelho = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          obrigatorio
              ? 'Como terminou a negociação? *'
              : 'Como terminou a negociação? (opcional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OpcaoFechamento(
                titulo: 'Vendido',
                descricao: 'Fechei a venda',
                icone: SFIcons.checkCircle,
                cor: _verde,
                selecionado: value == TipoFechamento.vendido,
                onTap: () => _select(TipoFechamento.vendido),
              ),
              const SizedBox(width: 10),
              _OpcaoFechamento(
                titulo: 'Perdido p/ concorrência',
                descricao: 'Comprou de outro',
                icone: SFIcons.close,
                cor: _vermelho,
                selecionado: value == TipoFechamento.perdido,
                onTap: () => _select(TipoFechamento.perdido),
              ),
            ],
          ),
        ),
        if (!obrigatorio && value == null) ...[
          const SizedBox(height: 6),
          Text(
            'Negociação em aberto',
            style: TextStyle(fontSize: 11, color: hintColor),
          ),
        ],
        if (erro != null) ...[
          const SizedBox(height: 6),
          Text(
            erro!,
            style: TextStyle(fontSize: 11, color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _OpcaoFechamento extends StatelessWidget {
  const _OpcaoFechamento({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final neutro = theme.hintColor;
    final fundo = selecionado
        ? cor.withValues(alpha: isDark ? 0.22 : 0.10)
        : Colors.transparent;
    final borda = selecionado ? cor : neutro.withValues(alpha: 0.35);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selecionado,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: fundo,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borda, width: selecionado ? 2 : 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 22, color: selecionado ? cor : neutro),
                const SizedBox(height: 6),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selecionado ? cor : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descricao,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, color: neutro),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
