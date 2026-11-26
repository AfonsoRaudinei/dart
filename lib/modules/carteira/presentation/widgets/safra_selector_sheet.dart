import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';

import '../../domain/entities/carteira_safra.dart';
import '../providers/carteira_providers.dart';
import 'safra_form_dialog.dart';

/// Abre o seletor de safra da Carteira: lista as safras, troca a ativa e
/// permite criar uma nova.
Future<void> showSafraSelectorSheet(BuildContext context) {
  return showSoloForteSheet<void>(
    context: context,
    builder: (_) => const SafraSelectorSheet(),
  );
}

class SafraSelectorSheet extends ConsumerStatefulWidget {
  const SafraSelectorSheet({super.key});

  @override
  ConsumerState<SafraSelectorSheet> createState() => _SafraSelectorSheetState();
}

class _SafraSelectorSheetState extends ConsumerState<SafraSelectorSheet> {
  static final DateFormat _fmt = DateFormat('dd/MM/yyyy');

  bool _trocando = false;

  Future<void> _ativar(CarteiraSafra safra) async {
    if (_trocando) return;
    if (safra.ativa) {
      Navigator.of(context).pop();
      return;
    }
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;

    setState(() => _trocando = true);
    try {
      await ref.read(carteiraRepositoryProvider).ativarSafra(safra.id, userId);
      ref.invalidate(safraAtivaProvider);
      ref.invalidate(safrasProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _trocando = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Não deu para trocar a safra. Tente novamente.'),
        ),
      );
    }
  }

  Future<void> _novaSafra() async {
    final criada = await showDialog<bool>(
      context: context,
      builder: (_) => const SafraFormDialog(),
    );
    if (criada == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final safrasAsync = ref.watch(safrasProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Safra',
              style: TextStyle(
                color: v.titleColor,
                fontSize: v.titleFontSize,
                fontWeight: v.titleWeight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cada safra tem seus próprios números.',
              style: TextStyle(color: v.subtitleColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: safrasAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Não deu para carregar as safras.',
                    style: TextStyle(color: v.subtitleColor),
                  ),
                ),
                data: (safras) {
                  if (safras.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhuma safra criada ainda.',
                        style: TextStyle(color: v.subtitleColor),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: safras.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: v.dividerColor),
                    itemBuilder: (_, i) {
                      final safra = safras[i];
                      return _SafraTile(
                        safra: safra,
                        periodo:
                            '${_fmt.format(safra.dataInicio)} → '
                            '${_fmt.format(safra.dataFim)}',
                        visuals: v,
                        enabled: !_trocando,
                        onTap: () => _ativar(safra),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _trocando ? null : _novaSafra,
              style: TextButton.styleFrom(
                foregroundColor: v.ghostText,
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova safra'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafraTile extends StatelessWidget {
  const _SafraTile({
    required this.safra,
    required this.periodo,
    required this.visuals,
    required this.enabled,
    required this.onTap,
  });

  final CarteiraSafra safra;
  final String periodo;
  final SoloForteSheetVisuals visuals;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = visuals;
    return Semantics(
      button: true,
      selected: safra.ativa,
      label: safra.ativa
          ? '${safra.nome}, safra ativa'
          : 'Ativar ${safra.nome}',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        safra.nome,
                        style: TextStyle(
                          color: v.titleColor,
                          fontSize: 15,
                          fontWeight: safra.ativa
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        periodo,
                        style: TextStyle(color: v.subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (safra.ativa)
                  Icon(Icons.check_rounded, color: v.accent, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
