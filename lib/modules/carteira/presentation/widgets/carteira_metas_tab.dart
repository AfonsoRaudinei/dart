import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/carteira_meta.dart';
import '../../domain/entities/categoria_global.dart';
import '../providers/carteira_providers.dart';
import 'meta_form_dialog.dart';
import 'safra_form_dialog.dart';

/// Aba "Metas" da tela Carteira.
///
/// Exibe:
/// - Campo de valor do grão (global)
/// - Safra ativa com botão para criar nova
/// - Lista de metas por categoria com progresso
class CarteiraMetasTab extends ConsumerStatefulWidget {
  const CarteiraMetasTab({super.key});

  @override
  ConsumerState<CarteiraMetasTab> createState() => _CarteiraMetasTabState();
}

class _CarteiraMetasTabState extends ConsumerState<CarteiraMetasTab> {
  late final TextEditingController _valorGraoController;
  bool _salvandoGrao = false;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _valorGraoController = TextEditingController();
  }

  @override
  void dispose() {
    _valorGraoController.dispose();
    super.dispose();
  }

  Future<void> _salvarValorGrao() async {
    final valor = double.tryParse(
      _valorGraoController.text.replaceAll(',', '.'),
    );
    if (valor == null || valor <= 0) return;
    if (_userId.isEmpty) return;

    setState(() => _salvandoGrao = true);
    try {
      await ref.read(carteiraRepositoryProvider).setValorGrao(_userId, valor);
      ref.invalidate(valorGraoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor do grão atualizado')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvandoGrao = false);
      }
    }
  }

  Future<void> _abrirNovaSafra() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const SafraFormDialog(),
    );
  }

  Future<void> _abrirMetaDialog(
    CategoriaGlobal categoria,
    CarteiraMeta? metaExistente,
  ) async {
    await showDialog<bool>(
      context: context,
      builder: (_) =>
          MetaFormDialog(categoria: categoria, metaExistente: metaExistente),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valorGraoAsync = ref.watch(valorGraoProvider);
    final safraAtivaAsync = ref.watch(safraAtivaProvider);
    final categoriasAsync = ref.watch(categoriasGlobaisProvider(_userId));
    final metasAsync = ref.watch(metasSafraAtivaProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionLabel('Valor do grão'),
        const SizedBox(height: 8),
        valorGraoAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (valor) {
            if (_valorGraoController.text.isEmpty && valor > 0) {
              _valorGraoController.text = valor.toStringAsFixed(2);
            }
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valorGraoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _salvandoGrao ? null : _salvarValorGrao,
                  child: _salvandoGrao
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Safra ativa'),
            TextButton.icon(
              onPressed: _abrirNovaSafra,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nova safra'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        safraAtivaAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (safra) {
            if (safra == null) {
              return _EmptyState(
                message: 'Nenhuma safra ativa',
                sub: 'Crie uma safra para definir metas',
                onAction: _abrirNovaSafra,
                actionLabel: '+ Nova safra',
              );
            }
            String fmt(DateTime d) =>
                '${d.day.toString().padLeft(2, '0')}/'
                '${d.month.toString().padLeft(2, '0')}/'
                '${d.year}';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          safra.nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${fmt(safra.dataInicio)} -> ${fmt(safra.dataFim)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 16),
        const _SectionLabel('Metas da safra ativa'),
        const SizedBox(height: 12),
        safraAtivaAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (safra) {
            if (safra == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Crie uma safra para definir metas por categoria.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return categoriasAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (categorias) {
                final ativas = categorias.where((c) => c.ativo).toList();
                if (ativas.isEmpty) {
                  return const Text(
                    'Nenhuma categoria ativa.',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return metasAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (metas) {
                    return Column(
                      children: ativas.map((cat) {
                        final meta = _findMetaByCategoria(metas, cat.id);
                        final progressoAsync = ref.watch(
                          progressoCategoriaProvider(cat.id),
                        );
                        return _MetaCategoriaItem(
                          categoria: cat,
                          meta: meta,
                          progressoAsync: progressoAsync,
                          onEdit: () => _abrirMetaDialog(cat, meta),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  CarteiraMeta? _findMetaByCategoria(
    List<CarteiraMeta> metas,
    String categoriaId,
  ) {
    for (final meta in metas) {
      if (meta.categoriaId == categoriaId) {
        return meta;
      }
    }
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.grey[600],
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String sub;
  final VoidCallback onAction;
  final String actionLabel;

  const _EmptyState({
    required this.message,
    required this.sub,
    required this.onAction,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _MetaCategoriaItem extends ConsumerWidget {
  final CategoriaGlobal categoria;
  final CarteiraMeta? meta;
  final AsyncValue<double> progressoAsync;
  final VoidCallback onEdit;

  const _MetaCategoriaItem({
    required this.categoria,
    required this.meta,
    required this.progressoAsync,
    required this.onEdit,
  });

  Color _parseCor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cor = _parseCor(categoria.cor);
    final unidade = categoria.unidadeLabel;
    final pct = progressoAsync.valueOrNull ?? 0.0;
    final metaQtd = meta?.quantidade;
    final metaLabel = metaQtd == null
        ? 'Sem meta definida'
        : 'Meta: ${metaQtd % 1 == 0 ? metaQtd.toInt() : metaQtd.toStringAsFixed(1)} $unidade';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria.nome,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  metaLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (metaQtd != null) ...[
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
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}
