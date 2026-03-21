import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/carteira_lancamento.dart';
import '../../domain/entities/categoria_global.dart';
import '../providers/carteira_providers.dart';

/// Dialog para registrar um lançamento de realizado.
///
/// Um lançamento representa uma quantidade vendida para um cliente
/// em uma categoria na safra ativa.
class LancamentoFormDialog extends ConsumerStatefulWidget {
  final CategoriaGlobal categoria;
  final String clienteId;
  final String clienteNome;

  const LancamentoFormDialog({
    super.key,
    required this.categoria,
    required this.clienteId,
    required this.clienteNome,
  });

  @override
  ConsumerState<LancamentoFormDialog> createState() =>
      _LancamentoFormDialogState();
}

class _LancamentoFormDialogState extends ConsumerState<LancamentoFormDialog> {
  final _quantidadeController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _nomeConcorrenteController = TextEditingController();
  final _motivoFechamentoController = TextEditingController();
  DateTime _dataLancamento = DateTime.now();
  DateTime? _dataFechamento;
  TipoFechamento? _tipoFechamento;
  bool _salvando = false;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacaoController.dispose();
    _nomeConcorrenteController.dispose();
    _motivoFechamentoController.dispose();
    super.dispose();
  }

  Future<void> _pickData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataLancamento,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dataLancamento = picked);
    }
  }

  Future<void> _pickDataFechamento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataFechamento ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dataFechamento = picked);
    }
  }

  Future<void> _salvar() async {
    final quantidade = double.tryParse(
      _quantidadeController.text.replaceAll(',', '.'),
    );
    if (quantidade == null || quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade válida')),
      );
      return;
    }

    if (_userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuário não autenticado')));
      return;
    }

    final safra = await ref.read(safraAtivaProvider.future);
    if (safra == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nenhuma safra ativa')));
      return;
    }

    setState(() => _salvando = true);
    try {
      final repo = ref.read(carteiraRepositoryProvider);
      final nomeConcorrente = _nomeConcorrenteController.text.trim();
      final motivoFechamento = _motivoFechamentoController.text.trim();
      final hasTipoFechamento = _tipoFechamento != null;
      final lancamento = CarteiraLancamento(
        id: const Uuid().v4(),
        userId: _userId,
        safraId: safra.id,
        categoriaId: widget.categoria.id,
        clienteId: widget.clienteId,
        quantidade: quantidade,
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
        tipoFechamento: _tipoFechamento,
        nomeConcorrente: hasTipoFechamento && nomeConcorrente.isNotEmpty
            ? nomeConcorrente
            : null,
        motivoFechamento: hasTipoFechamento && motivoFechamento.isNotEmpty
            ? motivoFechamento
            : null,
        dataFechamento: hasTipoFechamento ? _dataFechamento : null,
        dataLancamento: _dataLancamento,
        createdAt: DateTime.now(),
      );
      await repo.saveLancamento(lancamento);

      // Invalidar providers afetados
      ref.invalidate(
        lancamentosSafraProvider((
          categoriaId: widget.categoria.id,
          clienteId: widget.clienteId,
        )),
      );
      ref.invalidate(
        realizadoClienteCategoriaProvider((
          clienteId: widget.clienteId,
          categoriaId: widget.categoria.id,
        )),
      );
      ref.invalidate(progressoCategoriaProvider(widget.categoria.id));
      ref.invalidate(oportunidadesClienteProvider(widget.clienteId));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar lançamento: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unidade = widget.categoria.unidade.label;
    final cor = _parseCor(widget.categoria.cor);
    final fmt =
        '${_dataLancamento.day.toString().padLeft(2, '0')}/'
        '${_dataLancamento.month.toString().padLeft(2, '0')}/'
        '${_dataLancamento.year}';

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.categoria.nome,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantidadeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Quantidade vendida',
              suffixText: unidade,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickData,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmt, style: const TextStyle(fontSize: 15)),
                  const Icon(Icons.calendar_today_outlined, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tipo de fechamento',
              border: OutlineInputBorder(),
            ),
            child: SegmentedButton<TipoFechamento>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TipoFechamento.vendido,
                  label: Text('Vendido'),
                ),
                ButtonSegment(
                  value: TipoFechamento.perdido,
                  label: Text('Perdido para concorrente'),
                ),
              ],
              selected: _tipoFechamento == null
                  ? <TipoFechamento>{}
                  : <TipoFechamento>{_tipoFechamento!},
              onSelectionChanged: (selected) {
                setState(() {
                  _tipoFechamento = selected.isEmpty ? null : selected.first;
                  if (_tipoFechamento == null) {
                    _nomeConcorrenteController.clear();
                    _motivoFechamentoController.clear();
                    _dataFechamento = null;
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _tipoFechamento != null
                ? Column(
                    key: const ValueKey('fechamento_fields'),
                    children: [
                      InkWell(
                        onTap: _pickDataFechamento,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _dataFechamento == null
                                      ? 'Data do fechamento (opcional)'
                                      : DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_dataFechamento!),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              if (_dataFechamento != null) ...[
                                InkWell(
                                  onTap: () {
                                    setState(() => _dataFechamento = null);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nomeConcorrenteController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do concorrente (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _motivoFechamentoController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Motivo (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('no_concorrente_fields')),
          ),
          TextField(
            controller: _observacaoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registrar'),
        ),
      ],
    );
  }

  Color _parseCor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
