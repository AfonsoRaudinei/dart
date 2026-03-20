import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  DateTime _dataLancamento = DateTime.now();
  bool _salvando = false;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacaoController.dispose();
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
