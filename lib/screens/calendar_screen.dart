import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../models/scheduled_event.dart';
import '../models/study_session.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  void _showLogStudySheet() async {
    final paperId = ref.read(selectedPaperIdProvider);
    final db = DatabaseHelper.instance;
    final subjects = await db.getSubjectsByPaper(paperId);
    if (subjects.isEmpty || !mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
      builder: (context) => _QuickLogStudyForm(subjects: subjects, onComplete: _onDataChanged),
    );
  }

  void _showScheduleForm() async {
    final paperId = ref.read(selectedPaperIdProvider);
    final db = DatabaseHelper.instance;
    final subjects = await db.getSubjectsByPaper(paperId);
    if (subjects.isEmpty || !mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
      builder: (context) => _ScheduleTaskForm(subjects: subjects, onComplete: _onDataChanged),
    );
  }

  void _onDataChanged() {
    ref.invalidate(scheduleForTodayProvider);
    ref.invalidate(upcomingScheduleProvider);
    ref.invalidate(studyHoursPerDayProvider(7));
    ref.invalidate(activityHeatmapProvider(DateTime.now().subtract(const Duration(days: 365))));
    ref.invalidate(totalStudyHoursProvider);
    ref.invalidate(totalStudySessionsCountProvider);
    ref.invalidate(currentStreakProvider);
  }

  @override
  Widget build(BuildContext context) {
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
                                Text(dayStr, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.0)),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(monthStr, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.1)),
                                      Text(weekdayStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Consumer(builder: (context, ref, _) {
                              final name = ref.watch(userNameProvider);
                              return Text('Hey $name', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500, color: Colors.white70));
                            }),
                          ],
                        ),
                        const Spacer(),
                        Consumer(builder: (context, ref, _) {
                          final name = ref.watch(userNameProvider);
                          return Container(
                            width: 44, height: 44,
                            decoration: const BoxDecoration(color: AppColors.lavenderPurple, shape: BoxShape.circle),
                            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TodayMiniStats(),
                  const SizedBox(height: 24),

                  // Today's Schedule Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_rounded, color: AppColors.lavenderPurple, size: 20),
                        const SizedBox(width: 8),
                        Text("Today's Schedule", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showScheduleForm,
                          icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.lavenderPurple),
                          label: const Text('Add', style: TextStyle(color: AppColors.lavenderPurple, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TodayScheduleList(),
                  const SizedBox(height: 24),

                  // Upcoming
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text('Upcoming (14 days)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _UpcomingScheduleList(),
                  const SizedBox(height: 20),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.add_rounded, label: 'Log Study', color: AppColors.lavenderPurple, onTap: _showLogStudySheet)),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickAction(icon: Icons.event_rounded, label: 'Schedule', color: Colors.orange, onTap: _showScheduleForm)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            SliverPadding(padding: const EdgeInsets.only(bottom: 100), sliver: SliverToBoxAdapter(child: const SizedBox.shrink())),
          ],
        ),
      ),
    );
  }
}

// ─── Today's Mini Stats ───

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
        db.getTotalStudyHoursAllTime(),
        db.getCurrentStreak(),
      ]),
      builder: (context, snapshot) {
        final completed = snapshot.hasData ? snapshot.data![0] : 0;
        final planned = snapshot.hasData ? snapshot.data![1] : 0;
        final totalMin = snapshot.hasData ? snapshot.data![2] : 0;
        final streak = snapshot.hasData ? snapshot.data![3] : 0;
        final totalHours = (totalMin / 60).round();

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
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.small)),
        child: Column(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1)),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, height: 1.1)),
        ]),
      ),
    );
  }
}

// ─── Today's Schedule (Todo List) ───

class _TodayScheduleList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleForTodayProvider);
    return scheduleAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadius.card)),
              child: Column(children: [
                const Icon(Icons.event_available_rounded, size: 40, color: Colors.white24),
                const SizedBox(height: 12),
                const Text('No tasks scheduled for today', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Tap "Add" to schedule your study plan', style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ]),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadius.card)),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, i) {
                final item = items[i];
                final topicName = item['topic_name'] as String? ?? '';
                final subjectName = item['subject_name'] as String? ?? '';
                final isDone = (item['is_completed'] as int? ?? 0) == 1;

                return _ScheduleTodoTile(
                  topicName: topicName,
                  subjectName: subjectName,
                  isDone: isDone,
                  eventId: item['id'] as int,
                );
              },
            ),
          ),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Text('$e')),
    );
  }
}

class _ScheduleTodoTile extends ConsumerWidget {
  final String topicName;
  final String subjectName;
  final bool isDone;
  final int eventId;

  const _ScheduleTodoTile({required this.topicName, required this.subjectName, required this.isDone, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: GestureDetector(
        onTap: () async {
          await DatabaseHelper.instance.toggleScheduledEvent(eventId, !isDone);
          ref.invalidate(scheduleForTodayProvider);
          ref.invalidate(upcomingScheduleProvider);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppColors.lavenderPurple : Colors.transparent,
            border: Border.all(color: isDone ? AppColors.lavenderPurple : Colors.white38, width: 2),
          ),
          child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
      ),
      title: Text(topicName, style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.white,
        decoration: isDone ? TextDecoration.lineThrough : null,
        decorationColor: Colors.white54,
      )),
      subtitle: Text(subjectName, style: TextStyle(color: Colors.white54, fontSize: 12, decoration: isDone ? TextDecoration.lineThrough : null, decorationColor: Colors.white38)),
      trailing: GestureDetector(
        onTap: () async {
          await DatabaseHelper.instance.deleteScheduledEvent(eventId);
          ref.invalidate(scheduleForTodayProvider);
          ref.invalidate(upcomingScheduleProvider);
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white38),
        ),
      ),
    );
  }
}

// ─── Upcoming Schedule ───

class _UpcomingScheduleList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingScheduleProvider);
    return upcomingAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('No upcoming tasks', style: TextStyle(color: Colors.white38, fontSize: 14)),
          );
        }

        // Group by date
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final item in items) {
          final dateStr = (item['scheduled_date'] as String).substring(0, 10);
          grouped.putIfAbsent(dateStr, () => []).add(item);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: grouped.entries.map((entry) {
              final date = DateTime.tryParse(entry.key);
              final label = date != null
                  ? (date.difference(DateTime.now()).inDays == 1
                      ? 'Tomorrow'
                      : DateFormat('MMM d, EEE').format(date))
                  : entry.key;
              final items = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadius.small)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.lavenderPurple, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item['topic_name'] as String? ?? '', style: const TextStyle(color: Colors.white, fontSize: 14))),
                            Text(item['subject_name'] as String? ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Quick Action Button ───

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

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
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

// ─── Schedule Task Form ───

class _ScheduleTaskForm extends ConsumerStatefulWidget {
  final List<dynamic> subjects;
  final VoidCallback onComplete;
  const _ScheduleTaskForm({required this.subjects, required this.onComplete});

  @override
  ConsumerState<_ScheduleTaskForm> createState() => _ScheduleTaskFormState();
}

class _ScheduleTaskFormState extends ConsumerState<_ScheduleTaskForm> {
  dynamic _selectedSubject;
  String? _selectedChapter;
  dynamic _selectedTopic;
  DateTime _selectedDate = DateTime.now();

  List<dynamic> _subjectTopics = [];
  List<String> _chapters = [];
  List<dynamic> _chapterTopics = [];

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
      _loadTopicsForSubject(_selectedSubject.id!);
    }
  }

  Future<void> _loadTopicsForSubject(int subjectId) async {
    final topics = await DatabaseHelper.instance.getTopicsBySubject(subjectId);
    if (!mounted) return;
    setState(() {
      _subjectTopics = topics;
      _chapters = topics.map((t) => t.chapter).toSet().toList().cast<String>();
      _chapters.removeWhere((c) => c.isEmpty);
      _selectedChapter = _chapters.isNotEmpty ? _chapters.first : null;
      _updateChapterTopics();
    });
  }

  void _updateChapterTopics() {
    if (_selectedChapter != null) {
      _chapterTopics = _subjectTopics.where((t) => t.chapter == _selectedChapter).toList();
    } else {
      _chapterTopics = List.from(_subjectTopics);
    }
    _selectedTopic = _chapterTopics.isNotEmpty ? _chapterTopics.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Schedule Study Task', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        DropdownButtonFormField<dynamic>(
          decoration: _inputDeco('Select Subject'),
          value: _selectedSubject,
          items: widget.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() { _selectedSubject = val; _selectedChapter = null; _selectedTopic = null; _chapters = []; _chapterTopics = []; });
              _loadTopicsForSubject(val.id!);
            }
          },
        ),
        const SizedBox(height: 12),
        if (_chapters.isNotEmpty)
          DropdownButtonFormField<String>(
            decoration: _inputDeco('Select Chapter'),
            value: _selectedChapter,
            items: _chapters.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) { if (val != null) setState(() { _selectedChapter = val; _updateChapterTopics(); }); },
          ),
        if (_chapters.isNotEmpty) const SizedBox(height: 12),
        DropdownButtonFormField<dynamic>(
          decoration: _inputDeco('Select Topic'),
          value: _selectedTopic,
          items: _chapterTopics.map((t) => DropdownMenuItem(value: t, child: Text(t.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) { if (val != null) setState(() { _selectedTopic = val; }); },
        ),
        const SizedBox(height: 12),
        // Date picker
        Row(
          children: [
            Expanded(
              child: Text(_selectedDate == DateTime.now() ? 'Today' : DateFormat('MMM d, yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() { _selectedDate = picked; });
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.lavenderPurple),
              label: const Text('Change', style: TextStyle(color: AppColors.lavenderPurple, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lavenderPurple, padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill))),
            onPressed: _selectedTopic == null ? null : () async {
              await DatabaseHelper.instance.addScheduledEvent(ScheduledEvent(
                topicId: _selectedTopic!.id!,
                scheduledDate: _selectedDate,
              ));
              widget.onComplete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label, filled: true, fillColor: AppColors.cardWhite,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small), borderSide: const BorderSide(color: AppColors.lightGray)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}

// ─── Quick Log Study Form (kept from original) ───

class _QuickLogStudyForm extends ConsumerStatefulWidget {
  final List<dynamic> subjects;
  final VoidCallback onComplete;
  const _QuickLogStudyForm({required this.subjects, required this.onComplete});

  @override
  ConsumerState<_QuickLogStudyForm> createState() => _QuickLogStudyFormState();
}

class _QuickLogStudyFormState extends ConsumerState<_QuickLogStudyForm> {
  dynamic _selectedSubject;
  String? _selectedChapter;
  dynamic _selectedTopic;
  List<dynamic> _subjectTopics = [];
  List<String> _chapters = [];
  List<dynamic> _chapterTopics = [];
  int _selectedDuration = 30;
  final List<int> _durations = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
      _loadTopicsForSubject(_selectedSubject.id!);
    }
  }

  Future<void> _loadTopicsForSubject(int subjectId) async {
    final topics = await DatabaseHelper.instance.getTopicsBySubject(subjectId);
    if (!mounted) return;
    setState(() {
      _subjectTopics = topics;
      _chapters = topics.map((t) => t.chapter).toSet().toList().cast<String>();
      _chapters.removeWhere((c) => c.isEmpty);
      _selectedChapter = _chapters.isNotEmpty ? _chapters.first : null;
      _updateChapterTopics();
    });
  }

  void _updateChapterTopics() {
    if (_selectedChapter != null) {
      _chapterTopics = _subjectTopics.where((t) => t.chapter == _selectedChapter).toList();
    } else {
      _chapterTopics = List.from(_subjectTopics);
    }
    _selectedTopic = _chapterTopics.isNotEmpty ? _chapterTopics.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log Study Session', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        DropdownButtonFormField<dynamic>(
          decoration: _inputDeco('Select Subject'), value: _selectedSubject,
          items: widget.subjects.map((s) => DropdownMenuItem(value: s, child: SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Text(s.name, overflow: TextOverflow.ellipsis)))).toList(),
          onChanged: (val) { if (val != null) { setState(() { _selectedSubject = val; _selectedChapter = null; _selectedTopic = null; _chapters = []; _chapterTopics = []; }); _loadTopicsForSubject(val.id!); }},
        ),
        if (_chapters.isNotEmpty) ...[const SizedBox(height: 12), DropdownButtonFormField<String>(
          decoration: _inputDeco('Select Chapter'), value: _selectedChapter,
          items: _chapters.map((c) => DropdownMenuItem(value: c, child: SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Text(c)))).toList(),
          onChanged: (val) { if (val != null) setState(() { _selectedChapter = val; _updateChapterTopics(); }); },
        )],
        const SizedBox(height: 12),
        DropdownButtonFormField<dynamic>(
          decoration: _inputDeco('Select Topic'), value: _selectedTopic,
          items: _chapterTopics.map((t) => DropdownMenuItem(value: t, child: SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Text(t.name, overflow: TextOverflow.ellipsis)))).toList(),
          onChanged: (val) { if (val != null) setState(() { _selectedTopic = val; }); },
        ),
        const SizedBox(height: 20),
        Text('Study Duration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _durations.map((d) {
          final sel = _selectedDuration == d;
          final label = d >= 60 ? '${d ~/ 60}h ${d % 60 > 0 ? '${d % 60}m' : ''}' : '${d}m';
          return ChoiceChip(
            label: Text(label), selected: sel,
            selectedColor: AppColors.lavenderPurple, backgroundColor: AppColors.cardWhite,
            labelStyle: TextStyle(color: sel ? Colors.white : Colors.white, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            onSelected: (_) => setState(() => _selectedDuration = d),
          );
        }).toList()),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lavenderPurple, padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill))),
            onPressed: _selectedTopic == null ? null : () async {
              await DatabaseHelper.instance.addSession(StudySession(topicId: _selectedTopic!.id!, date: DateTime.now(), durationMinutes: _selectedDuration));
              widget.onComplete();
              if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Study session logged!'))); }
            },
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label, filled: true, fillColor: AppColors.cardWhite,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small), borderSide: const BorderSide(color: AppColors.lightGray)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
