import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/cliente_categoria.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/categoria_progress_bar.dart';

class CarteiraClienteScreen extends ConsumerWidget {
  const CarteiraClienteScreen({super.key, required this.clienteId});

  final String clienteId;
  static const Uuid _uuid = Uuid();

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null || normalized.length != 6) return const Color(0xFF9CA3AF);
    return Color(0xFF000000 | value);
  }

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

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: categorias.length,
                itemBuilder: (context, index) {
                  final categoria = categorias[index];
                  final registro = registrosByCategoria[categoria.id];
                  return CategoriaProgressBar(
                    nome: categoria.nome,
                    cor: _parseColor(categoria.cor),
                    percentual: registro?.percentualFechado ?? 0,
                    observacao: registro?.observacao,
                    onTap: () => _editRegistro(
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
