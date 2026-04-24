import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/core/contracts/opportunity_summary.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';

/// Seção expansível que exibe oportunidades abertas de um cliente.
/// Usada no formulário de Nova Visita (agenda/).
///
/// - Invisível se [clienteId] for null ou vazio
/// - Invisível se não houver oportunidades abertas
/// - Loading: LinearProgressIndicator compacto (height: 2)
/// - Tap em oportunidade → dialog de confirmação → [onTituloSelecionado]
///
/// ADR-029 — IOpportunityLookup
class OportunidadesClienteSection extends ConsumerStatefulWidget {
  /// ID do cliente selecionado no form. Null = oculta a seção.
  final String? clienteId;

  /// Callback chamado quando o usuário confirma usar uma oportunidade
  /// como título da visita.
  final void Function(String titulo) onTituloSelecionado;

  const OportunidadesClienteSection({
    super.key,
    required this.clienteId,
    required this.onTituloSelecionado,
  });

  @override
  ConsumerState<OportunidadesClienteSection> createState() =>
      _OportunidadesClienteSectionState();
}

class _OportunidadesClienteSectionState
    extends ConsumerState<OportunidadesClienteSection> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final clienteId = widget.clienteId;

    if (clienteId == null || clienteId.isEmpty) {
      return const SizedBox.shrink();
    }

    final oportunidadesAsync = ref.watch(
      clientOpportunitiesProvider(clienteId),
    );

    return oportunidadesAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (err, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'Oportunidades indisponíveis: $err',
          style: const TextStyle(fontSize: 11, color: Colors.red),
        ),
      ),
      data: (oportunidades) {
        if (oportunidades.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expandido = !_expandido),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _expandido
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Oportunidades em aberto (${oportunidades.length})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expandido) ...[
              const SizedBox(height: 4),
              ...oportunidades.map(
                (op) => _OportunidadeItem(
                  oportunidade: op,
                  onTap: () => _confirmarTitulo(context, op.categoryName),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmarTitulo(BuildContext context, String titulo) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usar como título da visita?'),
        content: Text(
          '"$titulo"',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      widget.onTituloSelecionado(titulo);
    }
  }
}

class _OportunidadeItem extends StatelessWidget {
  final OpportunitySummary oportunidade;
  final VoidCallback onTap;

  const _OportunidadeItem({required this.oportunidade, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = Color(oportunidade.categoryColor);
    final pct = oportunidade.closedPercent;
    final unit = oportunidade.unit;
    final labelValor = _buildLabelValor(oportunidade.referenceValuePerHa, unit);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${oportunidade.categoryName}  '
                          'R\$ ${oportunidade.totalOpportunityValue.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (labelValor != null)
                        Text(
                          labelValor,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _buildLabelValor(double valor, String unit) {
    if (valor <= 0) return null;
    if (unit == 'R\$/ha') {
      final n = valor % 1 == 0
          ? valor.toInt().toString()
          : valor.toStringAsFixed(1);
      return 'R\$ $n/ha';
    }
    final n = valor % 1 == 0
        ? valor.toInt().toString()
        : valor.toStringAsFixed(1);
    return '$n $unit';
  }
}
