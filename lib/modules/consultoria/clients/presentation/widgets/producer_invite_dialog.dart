import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_producer_invite_writer.dart';
import 'package:soloforte_app/core/contracts/i_producer_invite_writer_provider.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/modules/consultoria/services/agronomic_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef EnsureClientRemoteFn = Future<void> Function(String clientId);

/// Diálogo de geração de token (ADR-039).
///
/// Extraído de [ClientDetailScreen] para testabilidade: sync forçado do
/// cliente remoto + createInvite via contrato, com erros acionáveis.
class ProducerInviteDialog extends ConsumerStatefulWidget {
  const ProducerInviteDialog({
    super.key,
    required this.clientId,
    required this.clientName,
    this.ensureClientRemote,
    this.inviteWriter,
  });

  final String clientId;
  final String clientName;

  /// Override de teste; em produção usa [AgronomicSyncService.ensureClientRemote].
  final EnsureClientRemoteFn? ensureClientRemote;

  /// Override de teste; em produção usa [producerInviteWriterProvider].
  final IProducerInviteWriter? inviteWriter;

  static Future<void> show(
    BuildContext context, {
    required String clientId,
    required String clientName,
    EnsureClientRemoteFn? ensureClientRemote,
    IProducerInviteWriter? inviteWriter,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ProducerInviteDialog(
        clientId: clientId,
        clientName: clientName,
        ensureClientRemote: ensureClientRemote,
        inviteWriter: inviteWriter,
      ),
    );
  }

  @override
  ConsumerState<ProducerInviteDialog> createState() =>
      _ProducerInviteDialogState();
}

class _ProducerInviteDialogState extends ConsumerState<ProducerInviteDialog> {
  String? _token;
  DateTime? _expiresAt;
  Object? _error;
  var _loading = false;

  Future<void> _generateInvite() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // RLS de producer_client_links exige o client em public.clients.
      final ensure =
          widget.ensureClientRemote ??
          (clientId) =>
              AgronomicSyncService(Supabase.instance.client)
                  .ensureClientRemote(clientId);
      await ensure(widget.clientId);

      final injectedWriter = widget.inviteWriter;
      final IProducerInviteWriter writer =
          injectedWriter ?? ref.read(producerInviteWriterProvider);
      final invite = await writer.createInvite(widget.clientId);
      if (!mounted) return;
      setState(() {
        _token = invite.token;
        _expiresAt = invite.expiresAt.toLocal();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convite do produtor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gere um token para ${widget.clientName} vincular a conta dele a este cadastro.',
          ),
          const SizedBox(height: 16),
          if (_token != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F8F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _token!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (_expiresAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Válido até ${_formatDate(_expiresAt!)}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              userFacingError(
                _error,
                action: 'Não foi possível gerar o convite',
              ),
              style: const TextStyle(color: Color(0xFFFF3B30)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        if (_token != null)
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _token!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token copiado.')),
              );
            },
            child: const Text('Copiar'),
          ),
        FilledButton(
          onPressed: _loading ? null : _generateInvite,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_token == null ? 'Gerar token' : 'Gerar novo'),
        ),
      ],
    );
  }
}
