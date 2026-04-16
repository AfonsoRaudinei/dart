import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';

/// Detalhe de oportunidades em aberto por cliente.
/// Aberta via Navigator.push — sem rota pública. ADR-022.
class OportunidadesDetalheScreen extends ConsumerWidget {
  const OportunidadesDetalheScreen({
    super.key,
    required this.clienteId,
    required this.clienteNome,
  });

  final String clienteId;
  final String clienteNome;

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
    final oportunidadesAsync =
        ref.watch(oportunidadesClienteProvider(clienteId));

    return Scaffold(
      appBar: AppBar(title: Text(clienteNome)),
      body: oportunidadesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Erro ao carregar oportunidades.')),
        data: (oportunidades) {
          if (oportunidades.isEmpty) {
            return const Center(
              child: Text('Nenhuma oportunidade em aberto 🎯'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: oportunidades.length,
            itemBuilder: (context, index) {
              final op = oportunidades[index];
              final cor = _parseCor(op.categoria.cor);
              final unidade = op.categoria.unidade.label;
              final pct = op.progressoPct;

              String fmt(double v) =>
                  v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              op.categoria.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pct == 0
                                  ? Colors.grey[500]
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          backgroundColor: Colors.grey[200],
                          color: cor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Meta: ${fmt(op.metaQuantidade)} $unidade  ·  '
                        'Realizado: ${fmt(op.realizado)}  ·  '
                        'Faltam: ${fmt(op.restante)}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
