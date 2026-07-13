import 'package:flutter/material.dart';

import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/parametro_comparativo.dart';
import 'novo_case_form_helpers.dart';

class ParametroCard extends StatefulWidget {
  final ParametroComparativo parametro;
  final bool selected;
  final ValueChanged<ParametroComparativo> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ParametroCard({
    super.key,
    required this.parametro,
    required this.selected,
    required this.onChanged,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<ParametroCard> createState() => _ParametroCardState();
}

class _ParametroCardState extends State<ParametroCard> {
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _testemunhaCtrl;
  late final TextEditingController _testeCtrl;
  late final TextEditingController _unidadeCtrl;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.parametro.titulo);
    _testemunhaCtrl = TextEditingController(
      text: _formatInitial(widget.parametro.testemunha),
    );
    _testeCtrl = TextEditingController(
      text: _formatInitial(widget.parametro.teste),
    );
    _unidadeCtrl = TextEditingController(text: widget.parametro.unidade ?? '');
  }

  @override
  void didUpdateWidget(covariant ParametroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parametro.id != widget.parametro.id) {
      _tituloCtrl.text = widget.parametro.titulo;
      _testemunhaCtrl.text = _formatInitial(widget.parametro.testemunha);
      _testeCtrl.text = _formatInitial(widget.parametro.teste);
      _unidadeCtrl.text = widget.parametro.unidade ?? '';
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _testemunhaCtrl.dispose();
    _testeCtrl.dispose();
    _unidadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delta = widget.parametro.deltaPercent;
    final deltaColor = widget.parametro.isPositivo
        ? PremiumTokens.brandGreen
        : widget.parametro.isNegativo
        ? PremiumTokens.alertError
        : SoloForteSheetTokens.inputHint;

    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus && !widget.selected) widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SoloForteSheetTokens.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.selected
                ? PremiumTokens.brandGreen
                : PremiumTokens.hairlineLight,
          ),
          boxShadow: widget.selected
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    offset: Offset(0, 10),
                    blurRadius: 28,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: novoCaseTextInput(
                    _tituloCtrl,
                    'Título do parâmetro',
                    required: true,
                    onChanged: (_) => _emit(),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover parâmetro',
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: PremiumTokens.alertError,
                  ),
                ),
              ],
            ),
            const NovoCaseFDivider(),
            Row(
              children: [
                Expanded(
                  child: novoCaseTextInput(
                    _testemunhaCtrl,
                    'Testemunha',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: novoCaseTextInput(
                    _testeCtrl,
                    'Teste (produto)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
            const NovoCaseFDivider(),
            Row(
              children: [
                Expanded(
                  child: novoCaseTextInput(
                    _unidadeCtrl,
                    'Unidade (opcional)',
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.parametro.testemunha == 0
                        ? '--'
                        : '${delta >= 0 ? '+' : ''}${_formatPercent(delta)}%',
                    style: TextStyle(
                      color: deltaColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _emit() {
    final unidade = _unidadeCtrl.text.trim();
    widget.onChanged(
      widget.parametro.copyWith(
        titulo: _tituloCtrl.text.trim(),
        testemunha: _parse(_testemunhaCtrl.text) ?? 0.0,
        teste: _parse(_testeCtrl.text) ?? 0.0,
        unidade: unidade.isEmpty ? null : unidade,
        clearUnidade: unidade.isEmpty,
      ),
    );
  }

  static double? _parse(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  static String _formatInitial(double value) {
    if (value == 0) return '';
    return value.toString().replaceAll('.', ',');
  }

  static String _formatPercent(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}
