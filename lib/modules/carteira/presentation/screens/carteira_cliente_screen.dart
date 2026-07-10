import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:soloforte_app/modules/carteira/domain/entities/carteira_lancamento.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/cliente_categoria.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/lancamento_form_dialog.dart';

class CarteiraClienteScreen extends ConsumerWidget {
  const CarteiraClienteScreen({super.key, required this.clienteId});

  final String clienteId;
  static const Uuid _uuid = Uuid();

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = _userId;
    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    final clienteAsync = ref.watch(carteiraClienteByIdProvider(clienteId));
    final categoriasAsync = ref.watch(categoriasGlobaisProvider(userId));
    final registrosAsync = ref.watch(
      categoriasClienteProvider((userId: userId, clienteId: clienteId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: clienteAsync.when(
          data: (cliente) => Text(cliente?.name ?? 'Cliente'),
          loading: () => const Text('Carteira do Cliente'),
          error: (_, __) => const Text('Carteira do Cliente'),
        ),
      ),
      body: categoriasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Erro ao carregar categorias.')),
        data: (categorias) {
          if (categorias.isEmpty) {
            return const Center(child: Text('Nenhuma categoria ativa.'));
          }

          return registrosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Erro ao carregar registros.')),
            data: (registros) {
              final registrosByCategoria = <String, ClienteCategoria>{
                for (final r in registros) r.categoriaId: r,
              };
              final clienteNome = clienteAsync.valueOrNull?.name ?? 'Cliente';

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: categorias.length,
                itemBuilder: (context, index) {
                  final categoria = categorias[index];
                  final registro = registrosByCategoria[categoria.id];
                  return _CategoriaClienteItem(
                    categoria: categoria,
                    clienteId: clienteId,
                    clienteNome: clienteNome,
                    clientAreaHa: clienteAsync.valueOrNull?.areaTotal ?? 0.0,
                    registroLegado: registro,
                    onEditLegado: () => _editRegistro(
                      context,
                      ref,
                      userId: userId,
                      categoria: categoria,
                      registroAtual: registro,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editRegistro(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required CategoriaGlobal categoria,
    required ClienteCategoria? registroAtual,
  }) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => _EditPercentualDialog(registro: registroAtual),
    );
    if (result == null) return;

    final novoRegistro = ClienteCategoria(
      id: registroAtual?.id ?? _uuid.v4(),
      userId: userId,
      clienteId: clienteId,
      categoriaId: categoria.id,
      percentualFechado: result.percentual,
      observacao: result.observacao,
      updatedAt: DateTime.now(),
    );

    await ref
        .read(carteiraRepositoryProvider)
        .upsertClienteCategoria(novoRegistro);
    ref.invalidate(
      categoriasClienteProvider((userId: userId, clienteId: clienteId)),
    );
    ref.invalidate(todosRegistrosProvider(userId));
  }
}

class _CategoriaClienteItem extends ConsumerStatefulWidget {
  const _CategoriaClienteItem({
    required this.categoria,
    required this.clienteId,
    required this.clienteNome,
    required this.clientAreaHa,
    required this.registroLegado,
    required this.onEditLegado,
  });

  final CategoriaGlobal categoria;
  final String clienteId;
  final String clienteNome;
  final double clientAreaHa;
  final ClienteCategoria? registroLegado;
  final VoidCallback onEditLegado;

  @override
  ConsumerState<_CategoriaClienteItem> createState() =>
      _CategoriaClienteItemState();
}

class _CategoriaClienteItemState extends ConsumerState<_CategoriaClienteItem> {
  bool _historicoExpandido = false;

  Color _parseCor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _abrirLancamento() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => LancamentoFormDialog(
        categoria: widget.categoria,
        clienteId: widget.clienteId,
        clienteNome: widget.clienteNome,
        clientAreaHa: widget.clientAreaHa,
      ),
    );

    if (!mounted || saved != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lançamento registrado com sucesso.')),
    );
  }

  String _rotuloLancamento(CarteiraLancamento lancamento) {
    if (lancamento.quantidade > 0) {
      final qtd = lancamento.quantidade % 1 == 0
          ? lancamento.quantidade.toInt().toString()
          : lancamento.quantidade.toStringAsFixed(2);
      if (lancamento.closedPercent > 0) {
        final pct = lancamento.closedPercent % 1 == 0
            ? lancamento.closedPercent.toInt().toString()
            : lancamento.closedPercent.toStringAsFixed(1);
        return '$qtd ${widget.categoria.unidadeLabel} ($pct%)';
      }
      return '$qtd ${widget.categoria.unidadeLabel}';
    }
    if (lancamento.closedPercent > 0) {
      final pct = lancamento.closedPercent % 1 == 0
          ? lancamento.closedPercent.toInt().toString()
          : lancamento.closedPercent.toStringAsFixed(1);
      return '$pct% fechado';
    }
    return 'Em negociação';
  }

  @override
  Widget build(BuildContext context) {
    final cor = _parseCor(widget.categoria.cor);
    final unidade = widget.categoria.unidadeLabel;

    final metaAsync = ref.watch(metaCategoriaProvider(widget.categoria.id));
    final realizadoAsync = ref.watch(
      realizadoClienteCategoriaProvider((
        clienteId: widget.clienteId,
        categoriaId: widget.categoria.id,
      )),
    );
    final lancamentosAsync = ref.watch(
      lancamentosSafraProvider((
        categoriaId: widget.categoria.id,
        clienteId: widget.clienteId,
      )),
    );

    final meta = metaAsync.valueOrNull;
    final realizado = realizadoAsync.valueOrNull ?? 0.0;
    final pct = (meta != null && meta.quantidade > 0)
        ? (realizado / meta.quantidade * 100.0).clamp(0.0, 100.0)
        : 0.0;
    final totalHistorico = lancamentosAsync.valueOrNull?.length ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: widget.onEditLegado,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.categoria.nome,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _abrirLancamento,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Lançamento'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              if (meta != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Meta: ${meta.quantidade % 1 == 0 ? meta.quantidade.toInt() : meta.quantidade.toStringAsFixed(1)} $unidade  ·  Realizado: ${realizado % 1 == 0 ? realizado.toInt() : realizado.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          backgroundColor: Colors.grey[200],
                          color: cor,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Sem meta definida',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              if (widget.registroLegado != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Legado: ${widget.registroLegado!.percentualFechado}% fechado'
                  '${(widget.registroLegado!.observacao ?? '').trim().isNotEmpty ? ' · ${widget.registroLegado!.observacao}' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
              const SizedBox(height: 4),
              InkWell(
                onTap: () =>
                    setState(() => _historicoExpandido = !_historicoExpandido),
                child: Row(
                  children: [
                    Icon(
                      _historicoExpandido
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    Text(
                      'Histórico ($totalHistorico)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (_historicoExpandido)
                lancamentosAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (lancamentos) {
                    if (lancamentos.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 18, top: 4),
                        child: Text(
                          'Nenhum lançamento registrado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(left: 18, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: lancamentos.map((l) {
                          final d = l.dataLancamento;
                          final fmt =
                              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
                          final valorLabel = _rotuloLancamento(l);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '$fmt · $valorLabel'
                              '${l.observacao != null ? ' · ${l.observacao}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPercentualDialog extends StatefulWidget {
  const _EditPercentualDialog({required this.registro});

  final ClienteCategoria? registro;

  @override
  State<_EditPercentualDialog> createState() => _EditPercentualDialogState();
}

class _EditPercentualDialogState extends State<_EditPercentualDialog> {
  late int _percentual;
  late final TextEditingController _percentualController;
  late final TextEditingController _observacaoController;

  @override
  void initState() {
    super.initState();
    _percentual = widget.registro?.percentualFechado ?? 0;
    _percentualController = TextEditingController(text: '$_percentual');
    _observacaoController = TextEditingController(
      text: widget.registro?.observacao ?? '',
    );
  }

  @override
  void dispose() {
    _percentualController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atualizar fechamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _percentualController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Percentual (0-100)'),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed == null) return;
              final clamped = parsed.clamp(0, 100);
              setState(() => _percentual = clamped);
            },
          ),
          const SizedBox(height: 12),
          Slider(
            value: _percentual.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '$_percentual%',
            onChanged: (value) {
              final v = value.round();
              setState(() {
                _percentual = v;
                _percentualController.text = '$v';
              });
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _observacaoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = int.tryParse(_percentualController.text.trim());
            if (parsed == null || parsed < 0 || parsed > 100) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Informe um percentual de 0 a 100.'),
                ),
              );
              return;
            }

            final obs = _observacaoController.text.trim();
            Navigator.of(context).pop(
              _EditResult(
                percentual: parsed,
                observacao: obs.isEmpty ? null : obs,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _EditResult {
  const _EditResult({required this.percentual, required this.observacao});

  final int percentual;
  final String? observacao;
}
