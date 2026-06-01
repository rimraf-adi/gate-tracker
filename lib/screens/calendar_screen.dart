import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../models/study_session.dart';
import '../models/mock_test.dart';
import '../widgets/glass_card.dart';
import '../widgets/stats_ring.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/paper_chip.dart';

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

  void _onDataChanged() {
    ref.invalidate(studyHoursPerDayProvider(7));
    ref.invalidate(activityHeatmapProvider);
    ref.invalidate(totalStudyHoursProvider);
    ref.invalidate(totalStudySessionsCountProvider);
    ref.invalidate(currentStreakProvider);
    ref.invalidate(allPapersCompletedTopicsProvider);
    ref.invalidate(allPapersMockCountProvider);
    ref.invalidate(allPapersMockAvgProvider);
    ref.invalidate(completedTopicsTodayProvider);
    ref.invalidate(revisionHistoryProvider(ref.read(selectedPaperIdProvider)));
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
                  SizedBox(height: 16),
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
                                SizedBox(width: 8),
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
                            SizedBox(height: 6),
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
                            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: PaperChip(),
                  ),
                  SizedBox(height: 12),
                  _TodayMiniStats(),
                  SizedBox(height: 16),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _QuickAction(icon: Icons.add_rounded, label: 'Log Study', color: AppColors.lavenderPurple, onTap: _showLogStudySheet)),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // ───── Progress Analytics ─────
                  _SyllabusProgress(),
                  SizedBox(height: 24),
                  _HeatmapSection(),
                  SizedBox(height: 24),
                  _SubjectRadarChart(),
                  SizedBox(height: 24),
                  _MockTrendChart(),
                  SizedBox(height: 100),
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
    final totalMin = ref.watch(totalStudyHoursProvider).value ?? 0;
    final streak = ref.watch(currentStreakProvider).value ?? 0;
    final totalHours = (totalMin / 60).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _MiniChip(icon: Icons.check_circle_rounded, value: '$completed', label: 'done today', color: const Color(0xFF4CAF50)),
          SizedBox(width: 10),
          _MiniChip(icon: Icons.timer_rounded, value: '${totalHours}h', label: 'studied', color: Colors.orange),
          SizedBox(width: 10),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.small),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.06),
              color.withValues(alpha: 0.12),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1)),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, height: 1.1)),
        ]),
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
            SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

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
        SizedBox(height: 20),
        DropdownButtonFormField<dynamic>(
          decoration: _inputDeco('Select Subject'), value: _selectedSubject,
          items: widget.subjects.map((s) => DropdownMenuItem(value: s, child: SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Text(s.name, overflow: TextOverflow.ellipsis)))).toList(),
          onChanged: (val) { if (val != null) { setState(() { _selectedSubject = val; _selectedChapter = null; _selectedTopic = null; _chapters = []; _chapterTopics = []; }); _loadTopicsForSubject(val.id!); }},
        ),
        if (_chapters.isNotEmpty) ...[SizedBox(height: 12), DropdownButtonFormField<String>(
          decoration: _inputDeco('Select Chapter'), value: _selectedChapter,
          items: _chapters.map((c) => DropdownMenuItem(value: c, child: SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Text(c)))).toList(),
          onChanged: (val) { if (val != null) setState(() { _selectedChapter = val; _updateChapterTopics(); }); },
        )],
        SizedBox(height: 12),
        DropdownButtonFormField<dynamic>(
          decoration: _inputDeco('Select Topic'), value: _selectedTopic,
          items: _chapterTopics.map((t) => DropdownMenuItem(value: t, child: SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Text(t.name, overflow: TextOverflow.ellipsis)))).toList(),
          onChanged: (val) { if (val != null) setState(() { _selectedTopic = val; }); },
        ),
        SizedBox(height: 20),
        Text('Study Duration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _durations.map((d) {
          final sel = _selectedDuration == d;
          final label = d >= 60 ? '${d ~/ 60}h ${d % 60 > 0 ? '${d % 60}m' : ''}' : '${d}m';
          return ChoiceChip(
            label: Text(label), selected: sel,
            selectedColor: AppColors.lavenderPurple, backgroundColor: Theme.of(context).cardColor,
            labelStyle: TextStyle(color: sel ? Colors.white : Colors.white, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            onSelected: (_) => setState(() => _selectedDuration = d),
          );
        }).toList()),
        SizedBox(height: 24),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)))),
          SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lavenderPurple, padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill))),
            onPressed: _selectedTopic == null ? null : () async {
              await DatabaseHelper.instance.addSession(StudySession(topicId: _selectedTopic!.id!, date: DateTime.now(), durationMinutes: _selectedDuration));
              widget.onComplete();
              if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Study session logged!'))); }
            },
              child: Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label, filled: true, fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}

// ─────────────────────────────────────────────
// Analytics sections (moved from analytics_screen)
// ─────────────────────────────────────────────

class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: EdgeInsets.all(16),
        child: ActivityHeatmap(),
      ),
    );
  }
}

class _SyllabusProgress extends ConsumerWidget {
  const _SyllabusProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(allPapersProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Syllabus Coverage', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          papersAsync.when(
            data: (papers) {
              if (papers.isEmpty) return const SizedBox.shrink();
              return Column(
                children: papers.map((p) {
                  final progressAsync = ref.watch(aggregateProgressProvider(p.id!));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(p.isCustom ? Icons.edit_note_rounded : Icons.assignment_outlined, color: AppColors.neonLime, size: 26),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text(p.isCustom ? 'Custom Syllabus' : 'Built-in Papers', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          progressAsync.when(
                            data: (ratio) => StatsRing(progress: ratio, size: 52),
                            loading: () => SizedBox(width: 52, height: 52, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MockTrendChart extends ConsumerWidget {
  const _MockTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final testsAsync = ref.watch(mockTestsByPaperProvider(paperId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📈 Mock Test Trend', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.open_in_new_rounded, size: 20, color: AppColors.neonOrange),
                onPressed: () => Navigator.pushNamed(context, '/mock-tests'),
              ),
            ],
          ),
          SizedBox(height: 12),
          testsAsync.when(
            data: (tests) {
              if (tests.isEmpty) {
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/mock-tests'),
                  child: Container(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Icon(Icons.add_chart_rounded, size: 48, color: Colors.white24),
                            SizedBox(height: 8),
                            Text('Add your first mock test to see trends!', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final chronologicalTests = List<MockTest>.from(tests).reversed.toList();
              final spots = chronologicalTests.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final percentage = t.totalMarks > 0 ? (t.marksObtained / t.totalMarks) * 100 : 0.0;
                return FlSpot(idx.toDouble(), percentage);
              }).toList();

              return Container(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
                padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                child: SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          color: AppColors.neonOrange,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: AppColors.neonOrange.withValues(alpha: 0.12)),
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      maxY: 100,
                      minY: 0,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (val, _) => Text('${val.toInt()}%', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= chronologicalTests.length) return const SizedBox.shrink();
                              final name = chronologicalTests[idx].testName;
                              final displayName = name.length > 8 ? '${name.substring(0, 6)}..' : name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(displayName, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

class _SubjectRadarChart extends ConsumerWidget {
  const _SubjectRadarChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final radarAsync = ref.watch(subjectStrengthRadarProvider(paperId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Subject Mastery', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              _LegendDot(color: const Color(0xFF4CAF50), label: 'Strong'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.orange, label: 'Mid'),
              SizedBox(width: 12),
              _LegendDot(color: const Color(0xFFE57373), label: 'Weak'),
            ],
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SizedBox(
              height: 280,
              child: radarAsync.when(
                data: (subjects) {
                  if (subjects.length < 3) return Center(child: Text('Need at least 3 subjects', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))));

                  final strongEntries = subjects.map((s) {
                    final total = (s['total'] as int?) ?? 1;
                    return RadarEntry(value: ((s['strong'] as int?) ?? 0) / total * 100);
                  }).toList();
                  final midEntries = subjects.map((s) {
                    final total = (s['total'] as int?) ?? 1;
                    return RadarEntry(value: ((s['mid'] as int?) ?? 0) / total * 100);
                  }).toList();
                  final weakEntries = subjects.map((s) {
                    final total = (s['total'] as int?) ?? 1;
                    return RadarEntry(value: ((s['weak'] as int?) ?? 0) / total * 100);
                  }).toList();
                  final names = subjects.map((s) => (s['name'] ?? s['subject_name']) as String).toList();

                  return RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          fillColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          borderColor: const Color(0xFF4CAF50),
                          entryRadius: 3, dataEntries: strongEntries, borderWidth: 2,
                        ),
                        RadarDataSet(
                          fillColor: Colors.orange.withValues(alpha: 0.15),
                          borderColor: Colors.orange,
                          entryRadius: 3, dataEntries: midEntries, borderWidth: 2,
                        ),
                        RadarDataSet(
                          fillColor: const Color(0xFFE57373).withValues(alpha: 0.15),
                          borderColor: const Color(0xFFE57373),
                          entryRadius: 3, dataEntries: weakEntries, borderWidth: 2,
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData: BorderSide(color: Colors.white12),
                      titlePositionPercentageOffset: 0.15,
                      titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 9),
                      getTitle: (index, angle) {
                        final text = names[index];
                        return RadarChartTitle(text: text.length > 10 ? '${text.substring(0, 8)}..' : text);
                      },
                      tickCount: 4,
                      ticksTextStyle: TextStyle(color: Colors.transparent, fontSize: 10),
                      tickBorderData: BorderSide(color: Colors.white12),
                      gridBorderData: BorderSide(color: Colors.white12, width: 2),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 150),
                    swapAnimationCurve: Curves.linear,
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
