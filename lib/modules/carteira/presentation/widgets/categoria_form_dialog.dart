import 'package:flutter/material.dart';

class CategoriaFormResult {
  const CategoriaFormResult({required this.nome, required this.corHex});

  final String nome;
  final String corHex;
}

class CategoriaFormDialog extends StatefulWidget {
  const CategoriaFormDialog({
    super.key,
    this.initialNome,
    this.initialCorHex,
    this.title = 'Nova categoria',
  });

  final String? initialNome;
  final String? initialCorHex;
  final String title;

  @override
  State<CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<CategoriaFormDialog> {
  late final TextEditingController _nomeController;
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
  }

  @override
  void dispose() {
    _nomeController.dispose();
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
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
