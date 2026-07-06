import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../../core/html_templates/html_report_viewer.dart';
import '../../../../core/utils/share_position.dart';
import '../../../../core/contracts/i_client_lookup_provider.dart';
import '../../../../core/contracts/i_farm_lookup_provider.dart';
import '../../../../core/contracts/i_field_lookup_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_provider.dart';
import '../services/agenda_pdf_service.dart';
import '../services/agenda_visit_html_service.dart';
import '../widgets/day_event_card.dart';

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
    _currentWeekStart = _calcWeekStart(DateTime.now());
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
                  padding: const EdgeInsets.all(16),
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
    final isCurrentWeek = _currentWeekStart == _calcWeekStart(DateTime.now());

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Opacity(
            opacity: isCurrentWeek ? 0.3 : 1.0,
            child: IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: isCurrentWeek
                  ? null
                  : () {
                      setState(() {
                        _currentWeekStart = _currentWeekStart.subtract(
                          const Duration(days: 7),
                        );
                        _activeDayFilters.addAll({0, 1, 2, 3, 4, 5, 6});
                      });
                    },
            ),
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
                      icon: const Icon(Icons.picture_as_pdf),
                      tooltip: 'Exportar PDF da semana',
                      onPressed: _exportPdf,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _exportLoading = true);
    try {
      final weekEnd = _currentWeekStart.add(const Duration(days: 6));
      // Usar apenas os dias visiveis/filtrados no PDF
      final visibleDayKeys = _filteredDays().map(_dayKey).toSet();
      final allWeekEvents = ref
          .read(agendaProvider.notifier)
          .getEventsByDateRange(_currentWeekStart, weekEnd);
      final filteredEvents = allWeekEvents
          .where((e) => visibleDayKeys.contains(_dayKey(e.dataInicioPlanejada)))
          .toList();

      final clientLookup = ref.read(clientLookupProvider);
      final farmLookup = ref.read(iFarmLookupProvider);
      final service = AgendaPdfService(clientLookup, farmLookup);
      final bytes = await service.generateWeekPdf(
        filteredEvents,
        _currentWeekStart,
      );

      final dir = await getTemporaryDirectory();
      final fmt = DateFormat('yyyy-MM-dd');
      final fileName =
          'soloforte_agenda_${fmt.format(_currentWeekStart)}_${fmt.format(weekEnd)}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Planejamento Semanal SoloForte',
        sharePositionOrigin: sharePositionOriginFor(context),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  // ── Lógica de semana e filtro ─────────────────────────────────

  /// Calcula a segunda-feira da semana que contém [ref].
  /// weekday: 1=seg … 7=dom  →  subtrai (weekday - 1) dias.
  DateTime _calcWeekStart(DateTime ref) {
    return DateTime(
      ref.year,
      ref.month,
      ref.day,
    ).subtract(Duration(days: ref.weekday - 1));
  }

  /// Dias da semana atual visíveis:
  ///   - Semana atual: apenas dias >= hoje (hoje sempre incluso)
  ///   - Semanas futuras: todos os 7 dias
  List<DateTime> _visibleDays() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final weekNow = _calcWeekStart(today);
    final isCurrentWeek = _currentWeekStart == weekNow;

    return List.generate(
      7,
      (i) => _currentWeekStart.add(Duration(days: i)),
    ).where((d) => !isCurrentWeek || !d.isBefore(todayOnly)).toList();
  }

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
                    ? (theme.brightness == Brightness.dark
                          ? const Color(0xFF1E2428)
                          : const Color(0xFFF3F4F6))
                    : isActive
                    ? const Color(0xFF4ADE80)
                    : (theme.brightness == Brightness.dark
                          ? const Color(0xFF2A3136)
                          : const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: !isVisible
                        ? (theme.brightness == Brightness.dark
                              ? const Color(0xFF3A3A3C)
                              : const Color(0xFFD1D5DB))
                        : isActive
                        ? const Color(0xFF14532D)
                        : (theme.brightness == Brightness.dark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSunday
            ? (theme.brightness == Brightness.dark
                  ? const Color(0xFF1A3A1F)
                  : const Color(0xFFD1FAE5))
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? const Color(0xFF4ADE80)
              : (theme.brightness == Brightness.dark
                    ? const Color(0xFF2A3136)
                    : const Color(0xFFE5E7EB)),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayHeader(theme, day, events, isSunday),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nenhum evento agendado',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
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
                  onVisitHtml: _openVisitHtml,
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

  Future<void> _openVisitHtml(Event event) async {
    try {
      final agendaState = ref.read(agendaProvider);
      final session = event.visitSessionId == null
          ? agendaState.sessions
                .where((item) => item.eventoId == event.id)
                .firstOrNull
          : agendaState.sessions
                .where((item) => item.id == event.visitSessionId)
                .firstOrNull;
      final user = Supabase.instance.client.auth.currentUser;
      final agronomistNome =
          user?.userMetadata?['name']?.toString().trim().isNotEmpty == true
          ? user!.userMetadata!['name'].toString()
          : user?.email ?? 'Agrônomo';

      final service = AgendaVisitHtmlService(
        ref.read(clientLookupProvider),
        ref.read(iFarmLookupProvider),
        ref.read(iFieldLookupProvider),
      );
      final html = await service.renderEventVisit(
        event: event,
        session: session,
        agronomistNome: agronomistNome,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HtmlReportViewer(
            title: 'Visita - ${event.titulo}',
            htmlContent: html,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar HTML da visita: $e')),
      );
    }
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
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2A3136)
                : const Color(0xFFE5E7EB),
          ),
        ),
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
                    color: isSunday ? const Color(0xFF4ADE80) : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy', 'pt_BR').format(day),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E2428)
                    : const Color(0xFFF3F4F6),
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
