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
  final double clientAreaHa;

  const LancamentoFormDialog({
    super.key,
    required this.categoria,
    required this.clienteId,
    required this.clienteNome,
    required this.clientAreaHa,
  });

  @override
  ConsumerState<LancamentoFormDialog> createState() =>
      _LancamentoFormDialogState();
}

class _LancamentoFormDialogState extends ConsumerState<LancamentoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _percentController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _nomeConcorrenteController = TextEditingController();
  final _motivoFechamentoController = TextEditingController();
  DateTime _dataLancamento = DateTime.now();
  DateTime? _dataFechamento;
  TipoFechamento? _tipoFechamento;
  bool _salvando = false;
  String? _mensagemErro;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void dispose() {
    _scrollController.dispose();
    _percentController.dispose();
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

  void _rolarParaTopo() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _salvar() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _mensagemErro = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      _rolarParaTopo();
      return;
    }

    final percent = double.parse(
      _percentController.text.trim().replaceAll(',', '.'),
    );

    if (_userId.isEmpty) {
      setState(() => _mensagemErro = 'Usuário não autenticado.');
      return;
    }

    final meta = await ref.read(
      metaCategoriaProvider(widget.categoria.id).future,
    );
    if (meta == null || meta.quantidade <= 0) {
      setState(
        () => _mensagemErro =
            'Configure a meta desta categoria antes de lançar.',
      );
      _rolarParaTopo();
      return;
    }

    setState(() => _salvando = true);
    try {
      final repo = ref.read(carteiraRepositoryProvider);
      final safra = await repo.ensureSafraAtiva(_userId);
      ref.invalidate(safraAtivaProvider);

      final closedPercent = percent.clamp(0.0, 100.0);
      final quantidade = CarteiraLancamento.derivarQuantidade(
        metaQuantidade: meta.quantidade,
        closedPercent: closedPercent,
      );

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
        closedPercent: closedPercent,
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
      ref.invalidate(realizadoCategoriaProvider(widget.categoria.id));
      ref.invalidate(progressoCategoriaProvider(widget.categoria.id));
      ref.invalidate(oportunidadesClienteProvider(widget.clienteId));
      ref.invalidate(clientOpportunitiesProvider(widget.clienteId));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _mensagemErro = 'Erro ao salvar lançamento: $e');
        _rolarParaTopo();
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  String? _validarPercentual(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Informe o percentual fechado (0 a 100)';
    }
    final percent = double.tryParse(text.replaceAll(',', '.'));
    if (percent == null || percent < 0.0 || percent > 100.0) {
      return 'Use um valor entre 0 e 100';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cor = _parseCor(widget.categoria.cor);
    final metaAsync = ref.watch(metaCategoriaProvider(widget.categoria.id));
    final meta = metaAsync.valueOrNull;
    final unidadeLabel = widget.categoria.unidadeLabel;
    final fmt =
        '${_dataLancamento.day.toString().padLeft(2, '0')}/'
        '${_dataLancamento.month.toString().padLeft(2, '0')}/'
        '${_dataLancamento.year}';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mensagemErro != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _mensagemErro!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (metaAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (meta == null || meta.quantidade <= 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Configure a meta desta categoria na aba Metas antes de registrar.',
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Meta: ${_formatQuantidade(meta.quantidade)} $unidadeLabel',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              TextFormField(
                controller: _percentController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: _validarPercentual,
                decoration: const InputDecoration(
                  labelText: 'Percentual fechado *',
                  hintText: 'Ex.: 25',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
              ),
              Builder(builder: (context) {
                final raw = double.tryParse(
                  _percentController.text.replaceAll(',', '.'),
                );
                final validPercent = raw != null && raw >= 0.0 && raw <= 100.0;
                if (!validPercent || meta == null || meta.quantidade <= 0) {
                  return const SizedBox.shrink();
                }
                final pct = raw.clamp(0.0, 100.0);
                final realizado = CarteiraLancamento.derivarQuantidade(
                  metaQuantidade: meta.quantidade,
                  closedPercent: pct,
                );
                final oportunidadeVolume =
                    CarteiraLancamento.derivarOportunidadeVolume(
                  metaQuantidade: meta.quantidade,
                  closedPercent: pct,
                );
                final valorRef = widget.categoria.valorReferencia ?? 0.0;
                final areaHa = widget.clientAreaHa;
                final closedValuePerHa = valorRef * pct / 100;
                final residualValuePerHa = valorRef - closedValuePerHa;
                final residualPercent = 100.0 - pct;
                final totalOportunidade = residualValuePerHa * areaHa;
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Realizado: ${_formatQuantidade(realizado)} $unidadeLabel '
                        '(${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%)',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Em aberto: ${_formatQuantidade(oportunidadeVolume)} $unidadeLabel',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (valorRef > 0) ...[
                        Text(
                          'Fechado: ${closedValuePerHa.toStringAsFixed(2)} $unidadeLabel',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Residual: ${residualValuePerHa.toStringAsFixed(2)} $unidadeLabel '
                          '(${residualPercent.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Oportunidade total: R\$ ${totalOportunidade.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickData,
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
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nome do concorrente (opcional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _motivoFechamentoController,
                            maxLines: 2,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Motivo (opcional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('no_concorrente_fields'),
                      ),
              ),
              TextField(
                controller: _observacaoController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _salvar(),
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando || meta == null || meta.quantidade <= 0
              ? null
              : _salvar,
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

  String _formatQuantidade(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }
}
