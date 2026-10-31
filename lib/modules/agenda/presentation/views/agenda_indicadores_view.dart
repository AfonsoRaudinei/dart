import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_provider.dart';

/// View de Indicadores e Métricas
class AgendaIndicadoresView extends ConsumerWidget {
  const AgendaIndicadoresView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final pendingAccent = theme.colorScheme.outline;
    final progressAccent = const Color(0xFFFBBF24);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weekEvents = ref
        .read(agendaProvider.notifier)
        .getEventsByDateRange(weekStart, weekEnd);

    final totalEvents = weekEvents.length;
    final completedEvents = weekEvents
        .where((e) => e.status == EventStatus.concluido)
        .length;
    final pendingEvents = weekEvents
        .where((e) => e.status == EventStatus.agendado)
        .length;
    final inProgressEvents = weekEvents
        .where((e) => e.status == EventStatus.emAndamento)
        .length;

    final efficiency = totalEvents > 0
        ? (completedEvents / totalEvents * 100).toStringAsFixed(0)
        : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semana Atual',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildEfficiencyCard(theme, accent, efficiency, completedEvents > 0),
          const SizedBox(height: 24),
          Text(
            'Resumo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            theme,
            context,
            'Total de Eventos',
            totalEvents.toString(),
            Icons.event,
            accent,
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            theme,
            context,
            'Concluídos',
            completedEvents.toString(),
            Icons.check_circle,
            accent,
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            theme,
            context,
            'Em Andamento',
            inProgressEvents.toString(),
            Icons.pending,
            progressAccent,
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            theme,
            context,
            'Pendentes',
            pendingEvents.toString(),
            Icons.schedule,
            pendingAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard(
    ThemeData theme,
    Color accent,
    String efficiency,
    bool showPositiveTrend,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            'Eficiência',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                efficiency,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Icon(
            showPositiveTrend ? Icons.trending_up : Icons.trending_flat,
            color: accent,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.premiumHairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.premiumTextSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
