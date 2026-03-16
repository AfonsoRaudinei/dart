import 'package:flutter/material.dart';

class CategoriaFormResult {
  const CategoriaFormResult({
    required this.nome,
    required this.corHex,
    this.valorReal,
    this.valorDolar,
    this.sacasPorHa,
  });

  final String nome;
  final String corHex;
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
    this.title = 'Nova categoria',
  });

  final String? initialNome;
  final String? initialCorHex;
  final double? initialValorReal;
  final double? initialValorDolar;
  final double? initialSacasPorHa;
  final String title;

  @override
  State<CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<CategoriaFormDialog> {
  late final TextEditingController _nomeController;
  late final TextEditingController _valorRealController;
  late final TextEditingController _valorDolarController;
  late final TextEditingController _sacasPorHaController;
  late Color _selectedColor;
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
    _valorRealController = TextEditingController(
      text: widget.initialValorReal?.toString() ?? '',
    );
    _valorDolarController = TextEditingController(
      text: widget.initialValorDolar?.toString() ?? '',
    );
    _sacasPorHaController = TextEditingController(
      text: widget.initialSacasPorHa?.toString() ?? '',
    );

    _valorRealController.addListener(() => setState(() {}));
    _valorDolarController.addListener(() => setState(() {}));
    _sacasPorHaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorRealController.dispose();
    _valorDolarController.dispose();
    _sacasPorHaController.dispose();
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

  Widget _buildCalculoPreview() {
    final real = _parseNullableDouble(_valorRealController.text);
    final dolar = _parseNullableDouble(_valorDolarController.text);
    final sacas = _parseNullableDouble(_sacasPorHaController.text);

    if (sacas == null || sacas == 0) return const SizedBox.shrink();
    if (real == null && dolar == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custo por hectare',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 4),
          if (real != null)
            Text(
              'R\$ ${(real / sacas).toStringAsFixed(3)} sc/ha',
              style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A)),
            ),
          if (dolar != null)
            Text(
              'US\$ ${(dolar / sacas).toStringAsFixed(3)} sc/ha',
              style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Informe o nome da categoria';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cor',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
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
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : Border.all(color: Colors.transparent, width: 3),
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
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Referência de mercado (opcional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorRealController,
                    decoration: const InputDecoration(
                      labelText: 'R\$/grão',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      if (_parseNullableDouble(value) == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _valorDolarController,
                    decoration: const InputDecoration(
                      labelText: 'US\$/grão',
                      prefixText: 'US\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      if (_parseNullableDouble(value) == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sacasPorHaController,
              decoration: const InputDecoration(
                labelText: 'Produtividade (sacas/ha)',
                suffixText: 'sc/ha',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = _parseNullableDouble(value);
                if (parsed == null) return 'Valor inválido';
                if (parsed <= 0) return 'Deve ser maior que zero';
                return null;
              },
            ),
            _buildCalculoPreview(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.of(context).pop(
              CategoriaFormResult(
                nome: _nomeController.text.trim(),
                corHex: _colorToHex(_selectedColor),
                valorReal: _parseNullableDouble(_valorRealController.text),
                valorDolar: _parseNullableDouble(_valorDolarController.text),
                sacasPorHa: _parseNullableDouble(_sacasPorHaController.text),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
