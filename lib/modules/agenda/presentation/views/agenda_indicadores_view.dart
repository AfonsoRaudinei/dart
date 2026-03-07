import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_provider.dart';

/// View de Indicadores e Métricas
class AgendaIndicadoresView extends ConsumerWidget {
  const AgendaIndicadoresView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
          _buildEfficiencyCard(theme, efficiency),
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
            'Total de Eventos',
            totalEvents.toString(),
            Icons.event,
            const Color(0xFF4ADE80),
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            theme,
            'Concluídos',
            completedEvents.toString(),
            Icons.check_circle,
            const Color(0xFF4ADE80),
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            theme,
            'Em Andamento',
            inProgressEvents.toString(),
            Icons.pending,
            const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            theme,
            'Pendentes',
            pendingEvents.toString(),
            Icons.schedule,
            const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard(ThemeData theme, String efficiency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1A3A1F)
            : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4ADE80)),
      ),
      child: Column(
        children: [
          Text(
            'Eficiência',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4ADE80),
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
                  color: const Color(0xFF4ADE80),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Icon(Icons.trending_up, color: Color(0xFF4ADE80), size: 32),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
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
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2A3136)
              : const Color(0xFFE5E7EB),
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
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
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
