import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/glass_card.dart';
import '../models/mock_test.dart';
import '../models/topic.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  // Event markers cache
  Map<String, List<String>> _eventMarkers = {};
  bool _loadingMarkers = false;

  @override
  void initState() {
    super.initState();
    _loadEventMarkers();
  }

  Future<void> _loadEventMarkers() async {
    if (_loadingMarkers) return;
    setState(() => _loadingMarkers = true);
    
    final start = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
    
    final markers = await DatabaseHelper.instance.getEventDatesInRange(start, end);
    if (mounted) {
      setState(() {
        _eventMarkers = markers;
        _loadingMarkers = false;
      });
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    return _eventMarkers[key] ?? [];
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _showLogStudySheet() async {
    final paperId = ref.read(selectedPaperIdProvider);
    final db = DatabaseHelper.instance;
    final subjects = await db.getSubjectsByPaper(paperId);

    if (subjects.isEmpty || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) {
        return _QuickLogStudyForm(
          subjects: subjects,
          onComplete: () {
            _loadEventMarkers();
            ref.invalidate(studyHoursPerDayProvider(7));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _formatDateKey(_selectedDay);
    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthStr = DateFormat('MMMM').format(now);
    final weekdayStr = DateFormat('EEEE').format(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header with oversized date + greeting
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(dayStr, style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                )),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(monthStr, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w600, height: 1.1,
                                      )),
                                      Text(weekdayStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white54,
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Consumer(builder: (context, ref, _) {
                              final name = ref.watch(userNameProvider);
                              return Text('Hey $name', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500, color: Colors.white70,
                              ));
                            }),
                          ],
                        ),
                        const Spacer(),
                        Consumer(builder: (context, ref, _) {
                          return ref.watch(userNameProvider).isNotEmpty
                              ? Container(
                                  width: 44, height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.lavenderPurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      ref.watch(userNameProvider)[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Today's mini stat chips
                  _TodayMiniStats(),
                  const SizedBox(height: 24),

                  // Calendar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: TableCalendar(
                        firstDay: DateTime(2024, 1, 1),
                        lastDay: DateTime(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() { _calendarFormat = format; });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          _loadEventMarkers();
                        },
                        eventLoader: _getEventsForDay,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          formatButtonDecoration: BoxDecoration(
                            border: Border.all(color: AppColors.lavenderPurple.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          formatButtonTextStyle: const TextStyle(
                            color: AppColors.lavenderPurple, fontWeight: FontWeight.bold, fontSize: 12,
                          ),
                          titleTextStyle: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white,
                          ),
                          leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
                          rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                          headerPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54),
                          weekendStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppColors.limeGreen.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.lavenderPurple,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                          weekendTextStyle: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white54),
                          outsideTextStyle: const TextStyle(color: Colors.white24),
                          markersMaxCount: 4,
                          markerSize: 8,
                          markerMargin: const EdgeInsets.symmetric(horizontal: 2),
                          markersAlignment: Alignment.bottomCenter,
                          markersOffset: const PositionedOffset(bottom: 4),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (events.isEmpty) return const SizedBox.shrink();
                            final types = events.cast<String>();
                            return Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: types.map((type) {
                                  final sz = type == 'study' ? 7.0 : 5.0;
                                  Color dotColor;
                                  switch (type) {
                                    case 'study':
                                      dotColor = AppColors.lavenderPurple;
                                      break;
                                    case 'completed':
                                      dotColor = const Color(0xFF4CAF50);
                                      break;
                                    case 'mock':
                                      dotColor = const Color(0xFF42A5F5);
                                      break;
                                    case 'revision':
                                      dotColor = Colors.orange;
                                      break;
                                    case 'scheduled':
                                      dotColor = Colors.yellow.shade700;
                                      break;
                                    default:
                                      dotColor = Colors.white38;
                                  }
                                  return Container(
                                    width: sz, height: sz,
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Monthly Overview
                  _MonthlyOverview(),
                  const SizedBox(height: 20),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_rounded,
                            label: 'Log Study',
                            color: AppColors.lavenderPurple,
                            onTap: _showLogStudySheet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.open_in_new_rounded,
                            label: 'Mock Tests',
                            color: const Color(0xFF42A5F5),
                            onTap: () => Navigator.pushNamed(context, '/mock-tests'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected Day Events
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(_selectedDay),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_getEventsForDay(_selectedDay).length} activities',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Events list (SliverList for smooth scrolling)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 400,
                  child: _DayEventsPanel(dateKey: dateKey),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverToBoxAdapter(child: const SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayMiniStats extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TodayMiniStats> createState() => _TodayMiniStatsState();
}

class _TodayMiniStatsState extends ConsumerState<_TodayMiniStats> {
  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper.instance;
    return FutureBuilder<List<int>>(
      future: Future.wait([
        db.getCompletedTopicsCountToday(),
        db.getScheduledEventsForTodayCount(),
        db.getPendingRevisionsForTodayCount(),
        db.getTotalStudyHoursAllTime(),
        db.getCurrentStreak(),
      ]),
      builder: (context, snapshot) {
        final completed = snapshot.hasData ? snapshot.data![0] : 0;
        final scheduled = snapshot.hasData ? snapshot.data![1] : 0;
        final revisions = snapshot.hasData ? snapshot.data![2] : 0;
        final totalMin = snapshot.hasData ? snapshot.data![3] : 0;
        final streak = snapshot.hasData ? snapshot.data![4] : 0;
        final totalHours = (totalMin / 60).round();
        final planned = scheduled + revisions;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _MiniChip(icon: Icons.check_circle_rounded, value: '$completed', label: 'done today', color: const Color(0xFF4CAF50)),
              const SizedBox(width: 10),
              _MiniChip(icon: Icons.event_note_rounded, value: '$planned', label: 'planned', color: const Color(0xFF42A5F5)),
              const SizedBox(width: 10),
              _MiniChip(icon: Icons.timer_rounded, value: '${totalHours}h', label: 'studied', color: Colors.orange),
              const SizedBox(width: 10),
              _MiniChip(icon: Icons.local_fire_department_rounded, value: '$streak', label: 'day streak', color: AppColors.lavenderPurple),
            ],
          ),
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniChip({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1)),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, height: 1.1)),
          ],
        ),
      ),
    );
  }
}

class _MonthlyOverview extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MonthlyOverview> createState() => _MonthlyOverviewState();
}

class _MonthlyOverviewState extends ConsumerState<_MonthlyOverview> {
  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper.instance;
    final paperId = ref.watch(selectedPaperIdProvider);
    return FutureBuilder(
      future: Future.wait([
        db.getAggregateProgress(paperId),
        db.getTotalMockTestsCount(paperId),
        db.getAverageMockScorePercentage(paperId),
        db.getCompletedSubjectsCount(paperId),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        final progress = (snapshot.hasData ? snapshot.data![0] as double : 0.0);
        final mockCount = (snapshot.hasData ? snapshot.data![1] as int : 0);
        final avgScore = (snapshot.hasData ? snapshot.data![2] as double : 0.0);
        final subjectsDone = (snapshot.hasData ? snapshot.data![3] as int : 0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_rounded, color: AppColors.lavenderPurple, size: 20),
                    const SizedBox(width: 8),
                    Text('Monthly Progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress ring + key stats
                Row(
                  children: [
                    SizedBox(
                      width: 72, height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation(AppColors.lavenderPurple),
                          ),
                          Text('${(progress * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _StatBar(label: 'Syllabus', value: '${(progress * 100).toInt()}%', fraction: progress, color: AppColors.lavenderPurple),
                          const SizedBox(height: 10),
                          _StatBar(label: 'Mock Avg', value: '${avgScore.toStringAsFixed(0)}%', fraction: avgScore / 100, color: const Color(0xFF42A5F5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatPill(icon: Icons.assignment_turned_in_rounded, value: '$subjectsDone', label: 'subjects done', color: const Color(0xFF4CAF50)),
                    const SizedBox(width: 10),
                    _StatPill(icon: Icons.quiz_rounded, value: '$mockCount', label: 'mock tests', color: const Color(0xFF42A5F5)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final Color color;

  const _StatBar({required this.label, required this.value, required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 40, child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatPill({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _DayEventsPanel extends ConsumerWidget {
  final String dateKey;

  const _DayEventsPanel({required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarDayEventsProvider(dateKey));

    return eventsAsync.when(
      data: (events) {
        final studySessions = events['studySessions'] as List<Map<String, dynamic>>? ?? [];
        final completedTopics = events['completedTopics'] as List<Map<String, dynamic>>? ?? [];
        final mockTests = events['mockTests'] as List<MockTest>? ?? [];
        final revisions = events['revisions'] as List<Map<String, dynamic>>? ?? [];
        final scheduledEvents = events['scheduledEvents'] as List<Map<String, dynamic>>? ?? [];

        if (studySessions.isEmpty && completedTopics.isEmpty && mockTests.isEmpty && revisions.isEmpty && scheduledEvents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available_rounded, size: 48, color: Colors.black26),
                SizedBox(height: 12),
                Text(
                  'No activity on this day',
                  style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Study sessions and completions will appear here',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 100),
          children: [
            // Revisions
            ...revisions.map((r) {
              final topicName = r['topic_name'] as String? ?? 'Unknown';
              final subjectName = r['subject_name'] as String? ?? '';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neonOrange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.replay_rounded, color: AppColors.neonOrange, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topicName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkSurface,
                                    fontSize: 18,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (subjectName.isNotEmpty)
                              Text(
                                subjectName,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.neonOrange,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'Revision Due',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Scheduled Events
            ...scheduledEvents.map((e) {
              final topicName = e['topic_name'] as String? ?? 'Unknown';
              final subjectName = e['subject_name'] as String? ?? '';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neonLime.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.event_note_rounded, color: AppColors.neonLime, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topicName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkSurface,
                                    fontSize: 18,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (subjectName.isNotEmpty)
                              Text(
                                subjectName,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.neonLime,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'Planned',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Study Sessions
            ...studySessions.map((s) {
              final topicName = s['topic_name'] as String? ?? 'Unknown';
              final subjectName = s['subject_name'] as String? ?? '';
              final duration = s['duration_minutes'] as int? ?? 0;
              final label = duration >= 60
                  ? '${duration ~/ 60}h ${duration % 60 > 0 ? '${duration % 60}m' : ''}'
                  : '${duration}m';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.neonPurple, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topicName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkSurface,
                                    fontSize: 18,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (subjectName.isNotEmpty)
                              Text(
                                subjectName,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Completed topics
            ...completedTopics.map((t) {
              final topicName = t['topic_name'] as String? ?? 'Unknown';
              final subjectName = t['subject_name'] as String? ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topicName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subjectName.isNotEmpty)
                              Text(
                                subjectName,
                                style: const TextStyle(fontSize: 12, color: Colors.black45),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Mock tests
            ...mockTests.map((test) {
              final percentage = test.totalMarks > 0
                  ? (test.marksObtained / test.totalMarks * 100).toStringAsFixed(1)
                  : '0.0';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.quiz_rounded, color: Color(0xFF42A5F5), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test.testName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkSurface,
                                    fontSize: 18,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${test.marksObtained} / ${test.totalMarks} marks',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLogStudyForm extends ConsumerStatefulWidget {
  final List<Subject> subjects;
  final VoidCallback onComplete;

  const _QuickLogStudyForm({required this.subjects, required this.onComplete});

  @override
  ConsumerState<_QuickLogStudyForm> createState() => _QuickLogStudyFormState();
}

class _QuickLogStudyFormState extends ConsumerState<_QuickLogStudyForm> {
  Subject? _selectedSubject;
  String? _selectedChapter;
  Topic? _selectedTopic;

  List<Topic> _subjectTopics = [];
  List<String> _chapters = [];
  List<Topic> _chapterTopics = [];

  int _selectedDuration = 30;
  final List<int> _durations = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
      _loadTopicsForSubject(_selectedSubject!.id!);
    }
  }

  Future<void> _loadTopicsForSubject(int subjectId) async {
    final topics = await DatabaseHelper.instance.getTopicsBySubject(subjectId);
    if (!mounted) return;
    
    setState(() {
      _subjectTopics = topics;
      _chapters = topics.map((t) => t.chapter).toSet().toList();
      _chapters.removeWhere((c) => c.isEmpty); // Fallback for empty chapters
      
      _selectedChapter = _chapters.isNotEmpty ? _chapters.first : null;
      _updateChapterTopics();
    });
  }

  void _updateChapterTopics() {
    if (_selectedChapter != null) {
      _chapterTopics = _subjectTopics.where((t) => t.chapter == _selectedChapter).toList();
    } else {
      _chapterTopics = _subjectTopics; // If no chapters, show all
    }
    _selectedTopic = _chapterTopics.isNotEmpty ? _chapterTopics.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Study Session',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 20),
          
          // --- Subject Dropdown ---
          DropdownButtonFormField<Subject>(
            decoration: InputDecoration(
              labelText: 'Select Subject',
              filled: true,
              fillColor: AppColors.cardWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            initialValue: _selectedSubject,
            items: widget.subjects.map((s) {
              return DropdownMenuItem<Subject>(
                value: s,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSubject = val;
                  _selectedChapter = null;
                  _selectedTopic = null;
                  _chapters = [];
                  _chapterTopics = [];
                });
                _loadTopicsForSubject(val.id!);
              }
            },
          ),
          const SizedBox(height: 12),

          // --- Chapter Dropdown ---
          if (_chapters.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Chapter',
                filled: true,
                fillColor: AppColors.cardWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              initialValue: _selectedChapter,
              items: _chapters.map((c) {
                return DropdownMenuItem<String>(
                  value: c,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedChapter = val;
                    _updateChapterTopics();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          // --- Topic Dropdown ---
          DropdownButtonFormField<Topic>(
            decoration: InputDecoration(
              labelText: 'Select Topic',
              filled: true,
              fillColor: AppColors.cardWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            initialValue: _selectedTopic,
            items: _chapterTopics.map((t) {
              return DropdownMenuItem<Topic>(
                value: t,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Text(t.name, overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedTopic = val;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          
          Text(
            'Study Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durations.map((d) {
              final isSelected = _selectedDuration == d;
              final label = d >= 60 ? '${d ~/ 60}h ${d % 60 > 0 ? '${d % 60}m' : ''}' : '${d}m';
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: AppColors.lavenderPurple,
                backgroundColor: AppColors.cardWhite,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                onSelected: (_) {
                  setState(() {
                    _selectedDuration = d;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavenderPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  onPressed: _selectedTopic == null ? null : () async {
                    final session = StudySession(
                      topicId: _selectedTopic!.id!,
                      date: DateTime.now(),
                      durationMinutes: _selectedDuration,
                    );
                    await DatabaseHelper.instance.addSession(session);
                    widget.onComplete();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Study session logged!')),
                      );
                    }
                  },
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
