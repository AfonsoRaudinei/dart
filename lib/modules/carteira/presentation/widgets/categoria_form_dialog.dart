import 'package:flutter/material.dart';

import '../../domain/enums/unidade_categoria.dart';

class CategoriaFormResult {
  const CategoriaFormResult({
    required this.nome,
    required this.corHex,
    required this.unidade,
    this.valorReferencia,
    // Campos legados mantidos para compatibilidade dos call sites atuais.
    this.valorReal,
    this.valorDolar,
    this.sacasPorHa,
  });

  final String nome;
  final String corHex;
  final UnidadeCategoria unidade;
  final double? valorReferencia;
  final double? valorReal;
  final double? valorDolar;
  final double? sacasPorHa;
}

class CategoriaFormDialog extends StatefulWidget {
  const CategoriaFormDialog({
    super.key,
    this.initialNome,
    this.initialCorHex,
    this.initialValorReal,
    this.initialValorDolar,
    this.initialSacasPorHa,
    this.initialUnidade,
    this.initialValorReferencia,
    this.title = 'Nova categoria',
  });

  final String? initialNome;
  final String? initialCorHex;
  final double? initialValorReal;
  final double? initialValorDolar;
  final double? initialSacasPorHa;
  final UnidadeCategoria? initialUnidade;
  final double? initialValorReferencia;
  final String title;

  @override
  State<CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<CategoriaFormDialog> {
  late final TextEditingController _nomeController;
  late final TextEditingController _valorReferenciaController;
  late Color _selectedColor;
  UnidadeCategoria _unidade = UnidadeCategoria.realPorHa;

  final _formKey = GlobalKey<FormState>();
  static const List<Color> _palette = [
    Color(0xFF4ADE80),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFF9CA3AF),
    Color(0xFFFB923C),
    Color(0xFF34D399),
    Color(0xFFF472B6),
    Color(0xFF38BDF8),
    Color(0xFFE879F9),
    Color(0xFFBEF264),
  ];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.initialNome ?? '');
    _selectedColor = _hexToColor(widget.initialCorHex ?? '#4ADE80');
    _unidade = widget.initialUnidade ?? UnidadeCategoria.realPorHa;
    _valorReferenciaController = TextEditingController(
      text:
          (widget.initialValorReferencia ?? widget.initialValorReal)
              ?.toString() ??
          '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorReferenciaController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return const Color(0xFF4ADE80);
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    if (parsed == null) return const Color(0xFF4ADE80);
    return Color(parsed);
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).substring(2).toUpperCase()}';
  }

  double? _parseNullableDouble(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Informe o nome da categoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cor',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _palette.map((color) {
                          final isSelected =
                              _selectedColor.toARGB32() == color.toARGB32();
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        width: 3,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 3,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tipo de produto',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _UnidadeSelector(
                        selected: _unidade,
                        onChanged: (u) => setState(() => _unidade = u),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valorReferenciaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Custo / Referência (opcional)',
                          suffixText: _unidade.label,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          if (_parseNullableDouble(value) == null) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final valorRef = _parseNullableDouble(
                          _valorReferenciaController.text,
                        );
                        Navigator.of(context).pop(
                          CategoriaFormResult(
                            nome: _nomeController.text.trim(),
                            corHex: _colorToHex(_selectedColor),
                            unidade: _unidade,
                            valorReferencia: valorRef,
                            // Compat: call sites atuais ainda usam valorReal.
                            valorReal: valorRef,
                            valorDolar: widget.initialValorDolar,
                            sacasPorHa: widget.initialSacasPorHa,
                          ),
                        );
                      },
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnidadeSelector extends StatelessWidget {
  final UnidadeCategoria selected;
  final ValueChanged<UnidadeCategoria> onChanged;

  const _UnidadeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final unidades = UnidadeCategoria.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: unidades.map((u) {
        final isSelected = u == selected;
        final color = Theme.of(context).colorScheme.primary;
        return GestureDetector(
          onTap: () => onChanged(u),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              u.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
