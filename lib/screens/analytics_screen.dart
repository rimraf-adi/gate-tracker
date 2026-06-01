import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/stats_ring.dart';
import '../widgets/activity_heatmap.dart';
import '../models/mock_test.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Progress Analytics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studyHoursPerDayProvider(7));
            ref.invalidate(allPapersProvider);
            ref.invalidate(aggregateProgressProvider(paperId));
            ref.invalidate(weakTopicsProvider(paperId));
            ref.invalidate(mockTestsByPaperProvider(paperId));
            ref.invalidate(activityHeatmapProvider(DateTime.now().subtract(const Duration(days: 365))));
            ref.invalidate(totalStudyHoursProvider);
            ref.invalidate(totalStudySessionsCountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: const [
              _HeatmapSection(),
              SizedBox(height: 24),
              _StudyHoursChart(),
              SizedBox(height: 24),
              _SubjectRadarChart(),
              SizedBox(height: 24),
              _SyllabusProgress(),
              SizedBox(height: 24),
              _MockTrendChart(),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: EdgeInsets.all(16),
        child: ActivityHeatmap(),
      ),
    );
  }
}

class _StudyHoursChart extends ConsumerWidget {
  const _StudyHoursChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyDataAsync = ref.watch(studyHoursPerDayProvider(7));

    return studyDataAsync.when(
      data: (data) {
        // Calculate total hours logged this week
        final totalMinutes = data.fold<int>(0, (sum, item) => sum + (item['duration'] as int? ?? 0));
        final totalHours = totalMinutes / 60.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📚 Study Hours This Week',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${totalHours.toStringAsFixed(1)} hrs',
                    style: const TextStyle(
                      color: AppColors.lavenderPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      barGroups: _buildBarGroups(data),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(data),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                              final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              final dayNum = data[idx]['weekday'] as int? ?? 1;
                              final label = weekdays[(dayNum - 1) % 7];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    double maxHours = 2.0; // Default minimum scale
    for (final item in data) {
      final hours = (item['duration'] as int? ?? 0) / 60.0;
      if (hours > maxHours) {
        maxHours = hours;
      }
    }
    return maxHours * 1.25; // Add top padding
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final idx = entry.key;
      final val = entry.value;
      final mins = val['duration'] as int? ?? 0;
      final hours = mins / 60.0;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: AppColors.neonPurple,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(data) / 1.25,
              color: AppColors.darkSurface,
            ),
          )
        ],
      );
    }).toList();
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
          Text(
            'Syllabus Coverage',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          papersAsync.when(
            data: (papers) {
              if (papers.isEmpty) return const SizedBox.shrink();
              return Column(
                children: papers.map((p) {
                  final progressAsync = ref.watch(aggregateProgressProvider(p.id!));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            p.isCustom ? Icons.edit_note_rounded : Icons.assignment_outlined,
                            color: AppColors.neonLime,
                            size: 26,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.isCustom ? 'Custom Syllabus' : 'Built-in Papers',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textGray),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          progressAsync.when(
                            data: (ratio) => StatsRing(progress: ratio, size: 52),
                            loading: () => const SizedBox(width: 52, height: 52, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
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
              Text(
                '📈 Mock Test Trend',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 20, color: AppColors.neonOrange),
                onPressed: () {
                  Navigator.pushNamed(context, '/mock-tests');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          testsAsync.when(
            data: (tests) {
              if (tests.isEmpty) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/mock-tests');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Icon(Icons.add_chart_rounded, size: 48, color: Colors.white24),
                            SizedBox(height: 8),
                            Text(
                              'Add your first mock test to see trends!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Reverse list to show tests in chronological order (left to right)
              final chronologicalTests = List<MockTest>.from(tests).reversed.toList();
              final spots = chronologicalTests.asMap().entries.map((entry) {
                final idx = entry.key;
                final t = entry.value;
                final percentage = t.totalMarks > 0 ? (t.marksObtained / t.totalMarks) * 100 : 0.0;
                return FlSpot(idx.toDouble(), percentage);
              }).toList();

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
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
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.neonOrange.withValues(alpha: 0.12),
                          ),
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
                            getTitlesWidget: (val, _) => Text(
                              '${val.toInt()}%',
                              style: const TextStyle(fontSize: 10, color: AppColors.textGray, fontWeight: FontWeight.bold),
                            ),
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
                              // Truncate name if long
                              final displayName = name.length > 8 ? '${name.substring(0, 6)}..' : name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 9, color: AppColors.textGray, fontWeight: FontWeight.bold),
                                ),
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
            loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
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
              const SizedBox(width: 12),
              _LegendDot(color: Colors.orange, label: 'Mid'),
              const SizedBox(width: 12),
              _LegendDot(color: const Color(0xFFE57373), label: 'Weak'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadius.card)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SizedBox(
              height: 280,
              child: radarAsync.when(
                data: (subjects) {
                  if (subjects.length < 3) {
                    return const Center(child: Text('Need at least 3 subjects', style: TextStyle(color: AppColors.textGray)));
                  }
                  // Build three datasets: strong, mid, weak
                  final strongEntries = subjects.map((s) {
                    final total = (s['total'] as int?) ?? 1;
                    final val = ((s['strong'] as int?) ?? 0) / total * 100;
                    return RadarEntry(value: val);
                  }).toList();

                  final midEntries = subjects.map((s) {
                    final total = (s['total'] as int?) ?? 1;
                    final val = ((s['mid'] as int?) ?? 0) / total * 100;
                    return RadarEntry(value: val);
                  }).toList();

                  final weakEntries = subjects.map((s) {
                    final total = (s['total'] as int?) ?? 1;
                    final val = ((s['weak'] as int?) ?? 0) / total * 100;
                    return RadarEntry(value: val);
                  }).toList();

                  final subjectNames = subjects.map((s) => s['name'] as String).toList();

                  return RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          fillColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          borderColor: const Color(0xFF4CAF50),
                          entryRadius: 3,
                          dataEntries: strongEntries,
                          borderWidth: 2,
                        ),
                        RadarDataSet(
                          fillColor: Colors.orange.withValues(alpha: 0.15),
                          borderColor: Colors.orange,
                          entryRadius: 3,
                          dataEntries: midEntries,
                          borderWidth: 2,
                        ),
                        RadarDataSet(
                          fillColor: const Color(0xFFE57373).withValues(alpha: 0.15),
                          borderColor: const Color(0xFFE57373),
                          entryRadius: 3,
                          dataEntries: weakEntries,
                          borderWidth: 2,
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData: const BorderSide(color: Colors.white12),
                      titlePositionPercentageOffset: 0.15,
                      titleTextStyle: const TextStyle(color: AppColors.textWhite, fontSize: 9),
                      getTitle: (index, angle) {
                        final text = subjectNames[index];
                        return RadarChartTitle(text: text.length > 10 ? '${text.substring(0, 8)}..' : text);
                      },
                      tickCount: 4,
                      ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
                      tickBorderData: const BorderSide(color: Colors.white12),
                      gridBorderData: const BorderSide(color: Colors.white12, width: 2),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 150),
                    swapAnimationCurve: Curves.linear,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
