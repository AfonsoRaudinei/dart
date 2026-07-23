import 'package:flutter/material.dart';
import '../../../../core/session/local_session_identity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/carteira_meta.dart';
import '../../domain/entities/categoria_global.dart';
import '../providers/carteira_providers.dart';

/// Dialog para criar ou editar a meta de uma categoria na safra ativa.
class MetaFormDialog extends ConsumerStatefulWidget {
  final CategoriaGlobal categoria;
  final CarteiraMeta? metaExistente;

  const MetaFormDialog({
    super.key,
    required this.categoria,
    this.metaExistente,
  });

  @override
  ConsumerState<MetaFormDialog> createState() => _MetaFormDialogState();
}

class _MetaFormDialogState extends ConsumerState<MetaFormDialog> {
  late final TextEditingController _quantidadeController;
  bool _salvando = false;

  String get _userId => LocalSessionIdentity.resolveUserId();

  @override
  void initState() {
    super.initState();
    _quantidadeController = TextEditingController(
      text: widget.metaExistente?.quantidade.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nenhuma safra ativa')));
      }
      return;
    }

    setState(() => _salvando = true);
    try {
      final repo = ref.read(carteiraRepositoryProvider);
      final meta = CarteiraMeta(
        id: widget.metaExistente?.id ?? const Uuid().v4(),
        userId: _userId,
        safraId: safra.id,
        categoriaId: widget.categoria.id,
        quantidade: quantidade,
        createdAt: widget.metaExistente?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.metaExistente != null) {
        await repo.updateMeta(meta);
      } else {
        await repo.saveMeta(meta);
      }

      ref.invalidate(metasSafraAtivaProvider);
      ref.invalidate(metaCategoriaProvider(widget.categoria.id));
      ref.invalidate(progressoCategoriaProvider(widget.categoria.id));
      ref.invalidate(oportunidadesClienteProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar meta: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _parseCor(widget.categoria.cor);
    final unidade = widget.categoria.unidadeLabel;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.categoria.nome,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _quantidadeController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Meta',
          suffixText: unidade,
          border: const OutlineInputBorder(),
        ),
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
              : const Text('Salvar'),
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
