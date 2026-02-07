import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../controllers/kpi_controller.dart';
import '../../domain/kpi_metrics.dart';

class KpiDashboardWidget extends ConsumerWidget {
  const KpiDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, load all time or default period. Can be extended to accept filters from UI.
    final kpiAsync = ref.watch(kpiMetricsProvider(const KpiFilter()));

    return kpiAsync.when(
      data: (metrics) => _buildKpiContent(context, metrics),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Erro ao carregar KPIs: $e', style: SoloTextStyles.label),
        ),
      ),
    );
  }

  Widget _buildKpiContent(BuildContext context, KpiMetrics metrics) {
    if (metrics.totalVisits == 0) {
      return Container(
        padding: SoloSpacing.paddingCard,
        child: Column(
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: SoloForteColors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Sem dados de produtividade ainda.',
              style: SoloTextStyles.body.copyWith(
                color: SoloForteColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: SoloSpacing.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produtividade Geral', style: SoloTextStyles.headingMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Visitas',
                  value: metrics.totalVisits.toString(),
                  icon: Icons.check_circle_outline,
                  color: SoloForteColors.brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: 'Horas em Campo',
                  value: metrics.totalHoursInField.toStringAsFixed(1),
                  icon: Icons.timer_outlined,
                  color: SoloForteColors.greenIOS,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Média/Dia',
                  value: metrics.averageVisitsPerDay.toStringAsFixed(1),
                  icon: Icons.calendar_today_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: 'Duração Média',
                  value: '${metrics.averageVisitDurationMinutes.round()} min',
                  icon: Icons.access_time,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('Eficiência', style: SoloTextStyles.headingMedium),
          const SizedBox(height: 16),
          _KpiRow(
            label: 'Clientes Únicos',
            value: metrics.uniqueClientsVisited.toString(),
            icon: Icons.people_outline,
          ),
          const Divider(),
          _KpiRow(
            label: 'Visitas Longas (>4h)',
            value: '${metrics.percentageLongVisits.toStringAsFixed(1)}%',
            icon: Icons.warning_amber_rounded,
            valueColor: metrics.percentageLongVisits > 20
                ? SoloForteColors.error
                : SoloForteColors.textPrimary,
          ),
          if (metrics.mostVisitedClientId != null) ...[
            const Divider(),
            _KpiRow(
              label: 'Top Cliente (ID)',
              value:
                  metrics.mostVisitedClientId!, // In real app, would fetch name
              icon: Icons.star_border,
            ),
          ],

          const SizedBox(height: 24),
          Text('Atividades', style: SoloTextStyles.headingMedium),
          const SizedBox(height: 16),
          ...metrics.visitsByActivityType.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: SoloTextStyles.body),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SoloForteColors.grayLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      e.value.toString(),
                      style: SoloTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SoloRadius.radiusMd,
        boxShadow: SoloShadows.shadowCard,
        border: Border.all(color: SoloForteColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: SoloTextStyles.headingMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: SoloTextStyles.label),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _KpiRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: SoloForteColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: SoloTextStyles.body),
          const Spacer(),
          Text(
            value,
            style: SoloTextStyles.headingMedium.copyWith(
              fontSize: 16,
              color: valueColor ?? SoloForteColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
