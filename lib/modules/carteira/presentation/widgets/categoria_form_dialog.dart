import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_tipo_produto.dart';
import 'package:soloforte_app/modules/carteira/domain/enums/unidade_categoria.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/tipo_produto_form_dialog.dart';

class CategoriaFormResult {
  const CategoriaFormResult({
    required this.nome,
    required this.corHex,
    required this.unidadeCodigo,
    required this.unidadeLabel,
    required this.converteSacasHa,
    this.valorReferencia,
    this.valorReal,
    this.valorDolar,
    this.sacasPorHa,
  });

  final String nome;
  final String corHex;
  final String unidadeCodigo;
  final String unidadeLabel;
  final bool converteSacasHa;
  final double? valorReferencia;
  final double? valorReal;
  final double? valorDolar;
  final double? sacasPorHa;
}

class CategoriaFormDialog extends ConsumerStatefulWidget {
  const CategoriaFormDialog({
    super.key,
    required this.userId,
    this.initialNome,
    this.initialCorHex,
    this.initialValorReal,
    this.initialValorDolar,
    this.initialSacasPorHa,
    this.initialUnidadeCodigo,
    this.initialUnidadeLabel,
    this.initialConverteSacasHa,
    this.title = 'Nova categoria',
  });

  final String userId;
  final String? initialNome;
  final String? initialCorHex;
  final double? initialValorReal;
  final double? initialValorDolar;
  final double? initialSacasPorHa;
  final String? initialUnidadeCodigo;
  final String? initialUnidadeLabel;
  final bool? initialConverteSacasHa;
  final String title;

  @override
  ConsumerState<CategoriaFormDialog> createState() =>
      _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends ConsumerState<CategoriaFormDialog> {
  late final TextEditingController _nomeController;
  late final TextEditingController _valorReferenciaController;
  late Color _selectedColor;
  late String _unidadeCodigo;
  late String _unidadeLabel;
  late bool _converteSacasHa;

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
    _unidadeCodigo =
        widget.initialUnidadeCodigo ?? UnidadeCategoria.defaultCodigo;
    _unidadeLabel =
        widget.initialUnidadeLabel ?? UnidadeCategoria.defaultLabel;
    _converteSacasHa =
        widget.initialConverteSacasHa ??
        UnidadeCategoria.converteSacasHaForCodigo(_unidadeCodigo);
    _valorReferenciaController = TextEditingController(
      text: widget.initialValorReal?.toString() ?? '',
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

  void _selectTipo(CarteiraTipoProduto tipo) {
    setState(() {
      _unidadeCodigo = tipo.codigo;
      _unidadeLabel = tipo.label;
      _converteSacasHa = tipo.converteSacasHa;
    });
  }

  Future<void> _adicionarTipo() async {
    final result = await showSoloForteSheet<TipoProdutoFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (_) => const TipoProdutoFormDialog(),
    );
    if (result == null || !mounted) return;

    final repo = ref.read(carteiraRepositoryProvider);
    final novo = await repo.createTipoProdutoFromLabel(
      userId: widget.userId,
      label: result.label,
      converteSacasHa: result.converteSacasHa,
    );

    ref.invalidate(tiposProdutoProvider(widget.userId));
    _selectTipo(novo);
  }

  @override
  Widget build(BuildContext context) {
    final tiposAsync = ref.watch(tiposProdutoProvider(widget.userId));

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
                      tiposAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) => Text(
                          'Erro ao carregar tipos de produto.',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        data: (tipos) {
                          if (tipos.isNotEmpty &&
                              !tipos.any((t) => t.codigo == _unidadeCodigo)) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _selectTipo(tipos.first);
                            });
                          }
                          return _UnidadeSelector(
                            tipos: tipos,
                            selectedCodigo: _unidadeCodigo,
                            onChanged: _selectTipo,
                            onAddNew: _adicionarTipo,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valorReferenciaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Custo / Referência (opcional)',
                          suffixText: _unidadeLabel,
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
                      onPressed: tiposAsync.isLoading
                          ? null
                          : () {
                              if (!(_formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              final valorRef = _parseNullableDouble(
                                _valorReferenciaController.text,
                              );
                              Navigator.of(context).pop(
                                CategoriaFormResult(
                                  nome: _nomeController.text.trim(),
                                  corHex: _colorToHex(_selectedColor),
                                  unidadeCodigo: _unidadeCodigo,
                                  unidadeLabel: _unidadeLabel,
                                  converteSacasHa: _converteSacasHa,
                                  valorReferencia: valorRef,
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
  const _UnidadeSelector({
    required this.tipos,
    required this.selectedCodigo,
    required this.onChanged,
    required this.onAddNew,
  });

  final List<CarteiraTipoProduto> tipos;
  final String selectedCodigo;
  final ValueChanged<CarteiraTipoProduto> onChanged;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tipos.map((tipo) {
          final isSelected = tipo.codigo == selectedCodigo;
          return GestureDetector(
            onTap: () => onChanged(tipo),
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
                tipo.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: onAddNew,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  'Adicionar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
