import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/extensions/context_extensions.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import '../../../../core/html_templates/html_report_viewer.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/contracts/i_farm_lookup_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';
import '../../domain/planning_week.dart';
import '../providers/agenda_provider.dart';
import '../services/agenda_pdf_service.dart';
import '../services/agenda_planejamento_html_service.dart';
import '../services/agenda_visit_share.dart';
import '../widgets/day_event_card.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

/// View de Planejamento Semanal (modelo da skill)
class AgendaPlanejamentoView extends ConsumerStatefulWidget {
  const AgendaPlanejamentoView({super.key});

  @override
  ConsumerState<AgendaPlanejamentoView> createState() =>
      _AgendaPlanejamentoViewState();
}

class _AgendaPlanejamentoViewState
    extends ConsumerState<AgendaPlanejamentoView> {
  late DateTime _currentWeekStart;
  bool _exportLoading = false;
  final Set<int> _activeDayFilters = {0, 1, 2, 3, 4, 5, 6}; // 0=dom..6=sab

  @override
  void initState() {
    super.initState();
    _currentWeekStart = planningWeekStart(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agendaState = ref.watch(agendaProvider);

    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final weekEvents = ref
        .read(agendaProvider.notifier)
        .getEventsByDateRange(_currentWeekStart, weekEnd);

    final eventsByDay = _groupEventsByDay(weekEvents);
    final filteredDays = _filteredDays();

    return Column(
      children: [
        _buildWeekNavigation(theme),
        _buildDayFilters(theme),
        const SizedBox(height: 8),
        Expanded(
          child: agendaState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredDays.isEmpty
              ? const Center(child: Text('Nenhum dia selecionado.'))
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + context.fabSafeBottomPadding,
                  ),
                  itemCount: filteredDays.length,
                  itemBuilder: (context, index) {
                    final day = filteredDays[index];
                    final dayEvents = eventsByDay[_dayKey(day)] ?? [];
                    return _buildDayCard(context, theme, day, dayEvents);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeekNavigation(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.premiumHairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Semana anterior',
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.subtract(
                  const Duration(days: 7),
                );
                _activeDayFilters.addAll({0, 1, 2, 3, 4, 5, 6});
              });
            },
          ),
          Text(
            _formatWeekRange(_currentWeekStart),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _currentWeekStart = _currentWeekStart.add(
                      const Duration(days: 7),
                    );
                    _activeDayFilters.addAll({0, 1, 2, 3, 4, 5, 6});
                  });
                },
              ),
              _exportLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.ios_share_outlined),
                      tooltip: 'Exportar planejamento da semana',
                      onPressed: _exportWeekHtml,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportWeekHtml() async {
    setState(() => _exportLoading = true);
    try {
      final weekEnd = _currentWeekStart.add(const Duration(days: 6));
      final visibleDayKeys = _filteredDays().map(_dayKey).toSet();
      final allWeekEvents = ref
          .read(agendaProvider.notifier)
          .getEventsByDateRange(_currentWeekStart, weekEnd);
      final filteredEvents = allWeekEvents
          .where((e) => visibleDayKeys.contains(_dayKey(e.dataInicioPlanejada)))
          .toList();

      final clientLookup = ref.read(clientLookupProvider);
      final farmLookup = ref.read(iFarmLookupProvider);
      final user = Supabase.instance.client.auth.currentUser;
      final consultantName =
          user?.userMetadata?['name']?.toString().trim().isNotEmpty == true
          ? user!.userMetadata!['name'].toString()
          : user?.email;

      final htmlService = AgendaPlanejamentoHtmlService(
        clientLookup,
        farmLookup,
      );
      final html = await htmlService.renderWeekHtml(
        events: filteredEvents,
        weekStart: _currentWeekStart,
        consultantName: consultantName,
      );

      final fmt = DateFormat('yyyy-MM-dd');
      final fileBaseName =
          'soloforte_agenda_${fmt.format(_currentWeekStart)}_${fmt.format(weekEnd)}';

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HtmlReportViewer(
            title: 'Planejamento Semanal',
            htmlContent: html,
            fileBaseName: fileBaseName,
            pdfBytesProvider: () {
              final pdfService = AgendaPdfService(clientLookup, farmLookup);
              return pdfService.generateWeekPdf(
                filteredEvents,
                _currentWeekStart,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(e, action: 'Erro ao gerar planejamento'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  // ── Lógica de semana e filtro ─────────────────────────────────

  /// Os sete dias da semana exibida, inclusive os que já passaram.
  List<DateTime> _visibleDays() => planningWeekDays(_currentWeekStart);

  /// Aplica o filtro de chips sobre os dias visíveis.
  /// Índice: d.weekday % 7  →  seg=1, ter=2, …, sab=6, dom=0
  List<DateTime> _filteredDays() {
    return _visibleDays()
        .where((d) => _activeDayFilters.contains(d.weekday % 7))
        .toList();
  }

  /// Chips de filtro por dia da semana.
  Widget _buildDayFilters(ThemeData theme) {
    const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    // Índices 0..6 = dom, seg, ter, qua, qui, sex, sáb
    final visibleIndices = _visibleDays().map((d) => d.weekday % 7).toSet();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final isVisible = visibleIndices.contains(i);
          final isActive = _activeDayFilters.contains(i);
          return GestureDetector(
            onTap: isVisible
                ? () {
                    setState(() {
                      if (isActive) {
                        _activeDayFilters.remove(i);
                      } else {
                        _activeDayFilters.add(i);
                      }
                    });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !isVisible
                    ? context.premiumSurface
                    : isActive
                    ? theme.colorScheme.primary
                    : context.premiumHairline.withValues(alpha: 0.35),
              ),
              child: Center(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: !isVisible
                        ? context.premiumTextTertiary
                        : isActive
                        ? theme.colorScheme.onPrimary
                        : context.premiumTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    ThemeData theme,
    DateTime day,
    List<Event> events,
  ) {
    final isSunday = day.weekday == DateTime.sunday;
    final isToday = _isToday(day);
    // primaryContainer == primary neste tema (verde sólido), o que apagava o
    // texto do domingo; usa um tom suave da cor primária.
    final sundayFill = theme.colorScheme.primary.withValues(alpha: 0.10);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSunday ? sundayFill : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? theme.colorScheme.primary : context.premiumHairline,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push(AppRoutes.agendaDay(day)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildDayHeader(theme, day, events, isSunday),
          ),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nenhum evento agendado',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.premiumTextSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return DayEventCard(
                  event: events[index],
                  enablePlanningSwipeActions: true,
                  onVisitHtml: (event) =>
                      openAgendaVisitShare(context, ref, event: event),
                  onTap: () {
                    // Navegar para detalhes
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(
    ThemeData theme,
    DateTime day,
    List<Event> events,
    bool isSunday,
  ) {
    final completedCount = events
        .where((e) => e.status == EventStatus.concluido)
        .length;
    final totalCount = events.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.premiumHairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE', 'pt_BR').format(day),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSunday ? theme.colorScheme.primary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy', 'pt_BR').format(day),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.premiumTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.premiumSurface,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, List<Event>> _groupEventsByDay(List<Event> events) {
    final map = <String, List<Event>>{};
    for (final event in events) {
      final key = _dayKey(event.dataInicioPlanejada);
      map.putIfAbsent(key, () => []).add(event);
    }
    return map;
  }

  String _dayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatWeekRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('d MMM', 'pt_BR').format(start)} – ${DateFormat('d MMM yyyy', 'pt_BR').format(end)}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
