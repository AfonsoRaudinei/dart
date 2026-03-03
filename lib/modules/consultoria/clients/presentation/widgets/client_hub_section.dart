import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:soloforte_app/core/services/client_stats_service.dart';

/// Painel de estatísticas do Hub do Cliente.
///
/// Exibe contadores (visitas, ocorrências, desenhos), próximos eventos e
/// últimas visitas agregadas via [clientStatsProvider].
///
/// Extraído de [ClientDetailScreen] conforme PRD WS-4 / P6.
/// Bounded context: consultoria — NUNCA importar drawing/ ou operacao/.
class ClientStatsPanel extends ConsumerWidget {
  const ClientStatsPanel({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(clientStatsProvider(clientId));

    return statsAsync.when(
      loading: () => const _StatsLoadingSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contadores
          _sectionTitle(context, 'Resumo'),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(
                label: 'Visitas',
                value: '${stats.totalVisitas}',
                icon: Icons.directions_walk,
              ),
              const SizedBox(width: 12),
              _StatTile(
                label: 'Ocorrências',
                value: '${stats.totalOcorrencias}',
                icon: Icons.bug_report_outlined,
              ),
              const SizedBox(width: 12),
              _StatTile(
                label: 'Desenhos',
                value: '${stats.totalDesenhos}',
                icon: Icons.crop_square_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Próximos eventos
          if (stats.proximosEventos.isNotEmpty) ...[
            _sectionTitle(context, 'Próximos Eventos'),
            const SizedBox(height: 10),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    offset: Offset(0, 10),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < stats.proximosEventos.length; i++) ...[
                    _EventoItem(
                      titulo: stats.proximosEventos[i]['titulo'] as String? ??
                          'Evento',
                      data: _formatDate(
                        stats.proximosEventos[i]['data_inicio_planejada']
                            as String?,
                      ),
                      tipo: stats.proximosEventos[i]['tipo'] as String? ?? '',
                    ),
                    if (i < stats.proximosEventos.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color(0xFFE5E5EA),
                        indent: 44,
                        endIndent: 0,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Últimas visitas
          if (stats.ultimasVisitas.isNotEmpty) ...[
            _sectionTitle(context, 'Últimas Visitas'),
            const SizedBox(height: 10),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    offset: Offset(0, 10),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < stats.ultimasVisitas.length; i++) ...[
                    _VisitaItem(
                      data: _formatDate(
                        stats.ultimasVisitas[i]['start_at_real'] as String?,
                      ),
                      duracao:
                          stats.ultimasVisitas[i]['duracao_min'] as int?,
                    ),
                    if (i < stats.ultimasVisitas.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color(0xFFE5E5EA),
                        indent: 44,
                        endIndent: 0,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: Colors.black87,
          ),
        ),
      );

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return '—';
    }
  }
}

// ── Sub-widgets privados (usados apenas neste arquivo) ──────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              offset: Offset(0, 10),
              blurRadius: 32,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: PremiumTokens.brandGreen),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.07,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventoItem extends StatelessWidget {
  const _EventoItem({
    required this.titulo,
    required this.data,
    required this.tipo,
  });

  final String titulo;
  final String data;
  final String tipo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event,
              size: 14,
              color: PremiumTokens.brandGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$data${tipo.isNotEmpty ? ' · $tipo' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.07,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitaItem extends StatelessWidget {
  const _VisitaItem({required this.data, this.duracao});

  final String data;
  final int? duracao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk,
              size: 14,
              color: Color(0xFF3478F6),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            data,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: Colors.black87,
            ),
          ),
          if (duracao != null) ...[
            const SizedBox(width: 8),
            Text(
              '· ${duracao}min',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.07,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsLoadingSkeleton extends StatelessWidget {
  const _StatsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
