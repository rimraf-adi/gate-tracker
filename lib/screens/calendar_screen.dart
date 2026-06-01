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
    ref.invalidate(completedTopicsTodayProvider);
    ref.invalidate(scheduledEventsTodayCountProvider);
    final paperId = ref.read(selectedPaperIdProvider);
    ref.invalidate(totalCompletedTopicsProvider(paperId));
    ref.invalidate(totalMockTestsCountProvider(paperId));
    ref.invalidate(averageMockScoreProvider(paperId));
    ref.invalidate(completedSubjectsCountProvider(paperId));
    ref.invalidate(aggregateProgressProvider(paperId));
    ref.invalidate(totalNotesCountProvider);
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

                  // Metrics Bento Grid
                  _BentoMetricsGrid(),
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
            const SliverPadding(padding: EdgeInsets.only(bottom: 100), sliver: SliverToBoxAdapter(child: SizedBox.shrink())),
          ],
        ),
      ),
    );
  }
}

// ─── Today's Mini Stats ───

class _TodayMiniStats extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(completedTopicsTodayProvider).value ?? 0;
    final planned = ref.watch(scheduledEventsTodayCountProvider).value ?? 0;
    final totalMin = ref.watch(totalStudyHoursProvider).value ?? 0;
    final streak = ref.watch(currentStreakProvider).value ?? 0;
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

// ─── Bento Metrics Grid ───

class _BentoMetricsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);

    final totalMin = ref.watch(totalStudyHoursProvider).value ?? 0;
    final streak = ref.watch(currentStreakProvider).value ?? 0;
    final doneToday = ref.watch(completedTopicsTodayProvider).value ?? 0;
    final notes = ref.watch(totalNotesCountProvider).value ?? 0;
    final totalDone = ref.watch(totalCompletedTopicsProvider(paperId)).value ?? 0;
    final mockCount = ref.watch(totalMockTestsCountProvider(paperId)).value ?? 0;
    final mockAvg = ref.watch(averageMockScoreProvider(paperId)).value ?? 0.0;
    final subjectsDone = ref.watch(completedSubjectsCountProvider(paperId)).value ?? 0;
    final progress = ref.watch(aggregateProgressProvider(paperId)).value ?? 0.0;

    final hours = (totalMin / 60).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Row 1: Streak (big) + Hours (small)
          Row(
            children: [
              Expanded(flex: 3, child: _BentoCard(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: 'Day Streak',
                color: Colors.orange,
                large: true,
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _BentoCard(
                icon: Icons.timer_rounded,
                value: '${hours}h',
                label: 'Studied',
                color: AppColors.lavenderPurple,
              )),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Overall Progress (wide)
          _BentoProgressCard(label: 'Overall Progress', value: '${(progress * 100).toInt()}%', progress: progress),
          const SizedBox(height: 10),

          // Row 3: Topics done + Notes
          Row(
            children: [
              Expanded(child: _BentoCard(
                icon: Icons.check_circle_rounded,
                value: '$totalDone',
                label: 'Topics Done',
                color: const Color(0xFF4CAF50),
              )),
              const SizedBox(width: 10),
              Expanded(child: _BentoCard(
                icon: Icons.sticky_note_2_rounded,
                value: '$notes',
                label: 'Notes',
                color: const Color(0xFF42A5F5),
              )),
              const SizedBox(width: 10),
              Expanded(child: _BentoCard(
                icon: Icons.menu_book_rounded,
                value: '$doneToday',
                label: 'Done Today',
                color: AppColors.lavenderPurple,
              )),
            ],
          ),
          const SizedBox(height: 10),

          // Row 4: Sessions + Mock Avg
          Row(
            children: [
              Expanded(child: _BentoCard(
                icon: Icons.quiz_rounded,
                value: '$mockCount',
                label: 'Mock Tests',
                color: Colors.orange,
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _BentoCard(
                icon: Icons.analytics_rounded,
                value: mockCount > 0 ? '${mockAvg.toStringAsFixed(0)}%' : '—',
                label: 'Mock Average',
                color: const Color(0xFF42A5F5),
              )),
              const SizedBox(width: 10),
              Expanded(child: _BentoCard(
                icon: Icons.assignment_turned_in_rounded,
                value: '$subjectsDone',
                label: 'Subjects',
                color: const Color(0xFF4CAF50),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool large;

  const _BentoCard({
    required this.icon, required this.value, required this.label, required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(large ? 20 : 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: large ? 28 : 20),
          SizedBox(height: large ? 12 : 8),
          Text(value, style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: large ? 36 : 28,
          )),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: large ? 13 : 11)),
        ],
      ),
    );
  }
}

class _BentoProgressCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;

  const _BentoProgressCard({required this.label, required this.value, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56, height: 56,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(AppColors.lavenderPurple),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.lavenderPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.lavenderPurple, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('On Track', style: TextStyle(color: AppColors.lavenderPurple, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
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
