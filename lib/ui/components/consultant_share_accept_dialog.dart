import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/contracts/i_producer_invite_writer.dart';
import '../../core/utils/user_facing_error.dart';
import '../../modules/produtor/data/producer_link_models.dart';
import '../../modules/produtor/data/producer_link_repository.dart';

Future<void> showConsultantShareAcceptDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ConsultantShareAcceptDialog(),
  );
}

class _ConsultantShareAcceptDialog extends ConsumerStatefulWidget {
  const _ConsultantShareAcceptDialog();

  @override
  ConsumerState<_ConsultantShareAcceptDialog> createState() =>
      _ConsultantShareAcceptDialogState();
}

class _ConsultantShareAcceptDialogState
    extends ConsumerState<_ConsultantShareAcceptDialog> {
  final _tokenController = TextEditingController();
  var _submitting = false;
  Object? _error;
  List<ProducerLinkedClient> _links = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final links = await ref
          .read(producerLinkRepositoryProvider)
          .loadLinkedConsultantData();
      if (!mounted) return;
      setState(() => _links = links);
    } catch (_) {}
  }

  Future<void> _accept() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(producerLinkRepositoryProvider).acceptToken(token);
      _tokenController.clear();
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Receber dados'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole o código ou a mensagem de outro consultor. Você vê só o que ele marcou, em leitura.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Código',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error is FormatException
                    ? (_error! as FormatException).message
                    : userFacingError(
                        _error,
                        action: 'Não foi possível vincular',
                      ),
                style: const TextStyle(color: Color(0xFFFF3B30)),
              ),
            ],
            if (_links.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Já liberado para você'),
              const SizedBox(height: 8),
              for (final client in _links)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${client.name} · ${_grantedLabel(client.link.share)}',
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _accept,
          child: Text(_submitting ? 'Vinculando…' : 'Vincular'),
        ),
      ],
    );
  }
}

String _grantedLabel(ProducerShareSelection share) {
  final parts = <String>[
    if (share.farms) 'fazendas',
    if (share.fields) 'talhões',
    if (share.occurrences) 'ocorrências',
    if (share.reports) 'relatórios',
  ];
  return parts.isEmpty ? 'nenhum dado' : parts.join(', ');
}
