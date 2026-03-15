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
  late final TextEditingController _corController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.initialNome ?? '');
    _corController = TextEditingController(
      text: widget.initialCorHex ?? '#4ADE80',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _corController.dispose();
    super.dispose();
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _corController,
              decoration: const InputDecoration(labelText: 'Cor (hex)'),
              validator: (value) {
                final text = (value ?? '').trim();
                final hexRegex = RegExp(r'^#([A-Fa-f0-9]{6})$');
                if (!hexRegex.hasMatch(text)) {
                  return 'Use formato #RRGGBB';
                }
                return null;
              },
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
                corHex: _corController.text.trim().toUpperCase(),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
