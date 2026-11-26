import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/extensions/context_extensions.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/carteira_meta.dart';
import '../../domain/entities/categoria_global.dart';
import '../providers/carteira_providers.dart';
import 'carteira_ajuda_card.dart';
import 'carteira_segment_bar.dart';
import 'categoria_form_dialog.dart';
import 'meta_form_dialog.dart';
import 'safra_selector_sheet.dart';

/// Aba unificada "Categorias" da tela Carteira (metas + gestão de categorias).
///
/// Exibe:
/// - Campo de valor do grão (global)
/// - Estado vazio quando não há safra ativa (a troca de safra fica no topo
///   da Carteira)
/// - Lista de metas por categoria com progresso
class CarteiraMetasTab extends ConsumerStatefulWidget {
  const CarteiraMetasTab({super.key});

  @override
  ConsumerState<CarteiraMetasTab> createState() => _CarteiraMetasTabState();
}

class _CarteiraMetasTabState extends ConsumerState<CarteiraMetasTab> {
  @override
  void deactivate() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  String get _userId => LocalSessionIdentity.resolveUserId();

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

  Future<void> _criarCategoria() async {
    final result = await showSoloForteSheet<CategoriaFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: false,
      builder: (_) => CategoriaFormDialog(userId: _userId),
    );
    if (result == null) return;

    final categorias =
        await ref.read(categoriasGlobaisProvider(_userId).future);
    final now = DateTime.now();

    final nova = CategoriaGlobal(
      id: const Uuid().v4(),
      userId: _userId,
      nome: result.nome,
      cor: result.corHex,
      ativo: true,
      ordem: categorias.length,
      unidadeCodigo: result.unidadeCodigo,
      unidadeLabel: result.unidadeLabel,
      converteSacasHa: result.converteSacasHa,
      valorReferencia: result.valorReferencia,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(carteiraRepositoryProvider).saveCategoria(nova);
    ref.invalidate(categoriasGlobaisProvider(_userId));
  }

  Future<void> _editarCategoria(CategoriaGlobal categoria) async {
    final result = await showSoloForteSheet<CategoriaFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: false,
      builder: (_) => CategoriaFormDialog(
        userId: _userId,
        title: 'Editar categoria',
        initialNome: categoria.nome,
        initialCorHex: categoria.cor,
        initialValorReal: categoria.valorReferencia ?? categoria.valorReal,
        initialUnidadeCodigo: categoria.unidadeCodigo,
        initialUnidadeLabel: categoria.unidadeLabel,
        initialConverteSacasHa: categoria.converteSacasHa,
      ),
    );
    if (result == null) return;

    await ref.read(carteiraRepositoryProvider).updateCategoria(
          categoria.copyWith(
            nome: result.nome,
            cor: result.corHex,
            unidadeCodigo: result.unidadeCodigo,
            unidadeLabel: result.unidadeLabel,
            converteSacasHa: result.converteSacasHa,
            valorReferencia: result.valorReferencia,
          ),
        );

    ref.invalidate(categoriasGlobaisProvider(_userId));
  }

  Future<void> _desativarCategoria(CategoriaGlobal categoria) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desativar categoria'),
        content: Text(
          'Deseja desativar "${categoria.nome}"? Ela some das telas; '
          'os lançamentos já feitos ficam guardados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(carteiraRepositoryProvider).desativarCategoria(categoria.id);
    ref.invalidate(categoriasGlobaisProvider(_userId));
    ref.invalidate(todosRegistrosProvider(_userId));
  }

  @override
  Widget build(BuildContext context) {
    final valorGraoAsync = ref.watch(valorGraoProvider);
    final safraAtivaAsync = ref.watch(safraAtivaProvider);
    final categoriasAsync = ref.watch(categoriasGlobaisProvider(_userId));
    final metasAsync = ref.watch(metasSafraAtivaProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + context.fabSafeBottomPadding,
      ),
      children: [
        const _SectionLabel('Valor do grão'),
        const SizedBox(height: 8),
        valorGraoAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (valor) => _ValorGraoInlineItem(valor: valor),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 16),
        if (safraAtivaAsync.hasValue && safraAtivaAsync.value == null) ...[
          _EmptyState(
            message: 'Nenhuma safra ativa',
            sub: 'Crie uma safra para definir metas',
            onAction: () => showSafraSelectorSheet(context),
            actionLabel: '+ Nova safra',
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _criarCategoria,
            icon: const Icon(Icons.add),
            label: const Text('Nova categoria'),
          ),
        ),
        const SizedBox(height: 8),
        const CarteiraAjudaCard(
          segment: CarteiraSegment.categorias,
          margin: EdgeInsets.only(bottom: 12),
        ),
        const _SectionLabel('Metas da safra ativa'),
        const SizedBox(height: 12),
        safraAtivaAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (safra) {
            final semSafra = safra == null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (semSafra)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Crie uma safra para definir metas por categoria.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                categoriasAsync.when(
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

                    final valorGrao =
                        ref.watch(valorGraoProvider).valueOrNull ?? 0.0;

                    if (semSafra) {
                      return Column(
                        children: ativas.map((cat) {
                          return _MetaCategoriaItem(
                            categoria: cat,
                            meta: null,
                            valorGrao: valorGrao,
                            progressoAsync: const AsyncValue.data(0.0),
                            onEditMeta: () => _abrirMetaDialog(cat, null),
                            onEditCategoria: () => _editarCategoria(cat),
                            onDesativarCategoria: () =>
                                _desativarCategoria(cat),
                          );
                        }).toList(),
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
                              valorGrao: valorGrao,
                              progressoAsync: progressoAsync,
                              onEditMeta: () => _abrirMetaDialog(cat, meta),
                              onEditCategoria: () => _editarCategoria(cat),
                              onDesativarCategoria: () =>
                                  _desativarCategoria(cat),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
              ],
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

class _ValorGraoInlineItem extends ConsumerStatefulWidget {
  const _ValorGraoInlineItem({required this.valor});

  final double valor;

  @override
  ConsumerState<_ValorGraoInlineItem> createState() =>
      _ValorGraoInlineItemState();
}

class _ValorGraoInlineItemState extends ConsumerState<_ValorGraoInlineItem> {
  late final TextEditingController _controller;
  bool _editando = false;
  bool _salvando = false;
  String? _feedback;
  bool _feedbackErro = false;

  String get _userId => LocalSessionIdentity.resolveUserId();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _iniciarEdicao() {
    final valor = widget.valor;
    _controller.text = valor > 0 ? valor.toStringAsFixed(2) : '';
    setState(() {
      _editando = true;
      _feedback = null;
    });
  }

  void _cancelarEdicao() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editando = false;
      _feedback = null;
    });
  }

  Future<void> _salvar() async {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      setState(() {
        _feedback = 'Informe um valor válido maior que zero';
        _feedbackErro = true;
      });
      return;
    }
    if (_userId.isEmpty) return;

    setState(() {
      _salvando = true;
      _feedback = null;
    });
    try {
      await ref.read(carteiraRepositoryProvider).setValorGrao(_userId, parsed);
      ref.invalidate(valorGraoProvider);
      if (mounted) {
        setState(() {
          _editando = false;
          _feedback = 'Valor do grão atualizado';
          _feedbackErro = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedback = 'Erro ao salvar: $e';
          _feedbackErro = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  String _rotuloValor(double valor) {
    if (valor <= 0) return 'Não configurado';
    return '${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor)}'
        ' por saca';
  }

  @override
  Widget build(BuildContext context) {
    if (_editando) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !_salvando,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _salvar(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixText: 'R\$ ',
                    hintText: '0,00',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_feedback != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _feedback!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _feedbackErro
                            ? Theme.of(context).colorScheme.error
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 18),
            onPressed: _salvando ? null : _salvar,
            visualDensity: VisualDensity.compact,
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'Salvar',
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _salvando ? null : _cancelarEdicao,
            visualDensity: VisualDensity.compact,
            color: Colors.grey[600],
            tooltip: 'Cancelar',
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _rotuloValor(widget.valor),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: widget.valor > 0 ? null : Colors.grey[600],
                ),
              ),
              if (_feedback != null && !_feedbackErro)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _feedback!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: _iniciarEdicao,
          visualDensity: VisualDensity.compact,
          color: Colors.grey[600],
          tooltip: 'Editar valor do grão',
        ),
      ],
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
  final double valorGrao;
  final AsyncValue<double> progressoAsync;
  final VoidCallback onEditMeta;
  final VoidCallback onEditCategoria;
  final VoidCallback onDesativarCategoria;

  const _MetaCategoriaItem({
    required this.categoria,
    required this.meta,
    required this.valorGrao,
    required this.progressoAsync,
    required this.onEditMeta,
    required this.onEditCategoria,
    required this.onDesativarCategoria,
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
        : 'Meta da safra: ${NumberFormat('#,##0.#', 'pt_BR').format(metaQtd)} $unidade';
    final refLabel = categoria.rotuloReferencia();
    final equivLabel = categoria.rotuloEquivalenteSacasHa(valorGrao);

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
                if (refLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Valor de referência: $refLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (equivLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '$equivLabel (custo por hectare)',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
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
                            backgroundColor: context.isPremiumDark ? context.premiumHairline : Colors.grey[200],
                            color: cor,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pct.toStringAsFixed(0)}% da meta',
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEditMeta,
                visualDensity: VisualDensity.compact,
                color: Colors.grey[600],
                tooltip: 'Editar meta',
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
                tooltip: 'Mais ações da categoria',
                onSelected: (value) {
                  switch (value) {
                    case 'editar':
                      onEditCategoria();
                    case 'desativar':
                      onDesativarCategoria();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar categoria'),
                  ),
                  PopupMenuItem(
                    value: 'desativar',
                    child: Text('Desativar categoria'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
