# Step 10 — Analytics Screen

## Goal
Show progress and study data visually — lavender-tinted charts, circular progress rings per paper, and compact weak-spot cards. No text-heavy tables.

## Layout

```
┌──────────────────────────────┐
│  Progress                    │
│                              │
│  📚 Study Hours This Week    │
│  ┌──────────────────────────┐│
│  │  ▐▓▓▓▓▓▓▌               ││  ← Lavender bar chart
│  │  ▐▓▓▓▓▓▓▌  ▐▓▓▓▓▌      ││     (fl_chart)
│  │  ▐▓▓▓▓▓▓▌  ▐▓▓▓▓▌ ▐▓▌ ││
│  │  M    T    W    T    F  ││
│  └──────────────────────────┘│
│                              │
│  Syllabus Progress           │
│  ┌──────────────────────────┐│
│  │ CSE           ⭕ 78%    ││  ← StatsRing per paper
│  │ ECE           ⭕ 55%    ││
│  └──────────────────────────┘│
│                              │
│  ⚠ Weak Spots                │
│  ┌──────────────────────────┐│
│  │ Graph algorithms         ││  ← Small GlassCard
│  │ Stuck 10 days            ││
│  ├──────────────────────────┤│
│  │ Cache memory             ││
│  │ Stuck 8 days             ││
│  ├──────────────────────────┤│
│  │ Normal forms             ││
│  │ Stuck 5 days             ││
│  └──────────────────────────┘│
│                              │
│  📈 Mock Test Trend          │
│  ┌──────────────────────────┐│
│  │  ╱╲   ╱╲                ││  ← Line chart
│  │ ╱  ╲_╱  ╲╱╲             ││     Lavender line
│  │ 1   2   3   4   5        ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

## Implementation

### File: `lib/screens/analytics_screen.dart`

```dart
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Progress', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 24),
            _StudyHoursChart(),
            const SizedBox(height: 16),
            _SyllabusProgress(),
            const SizedBox(height: 16),
            _WeakSpots(),
            const SizedBox(height: 16),
            _MockTrendChart(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
```

### 1. Study hours bar chart — `_StudyHoursChart`
Uses `fl_chart` BarChart with lavender bars.

```dart
class _StudyHoursChart extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    // data from studyHoursPerDayProvider(7)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📚  Study Hours This Week', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                barGroups: _buildBarGroups(),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) => Text(['M','T','W','T','F','S','S'][val.toInt()],
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 2. Syllabus progress — `_SyllabusProgress`
Two rows, each showing paper name + StatsRing.

```dart
class _SyllabusProgress extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(allPapersProvider);
    return papersAsync.when(
      data: (papers) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Syllabus Progress', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...papers.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Row(
                  children: [
                    Expanded(child: Text(p.fullName, style: Theme.of(context).textTheme.titleMedium)),
                    StatsRing(progress: 0.78), // TODO: read from aggregateProgressProvider
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

### 3. Weak spots — `_WeakSpots`
Compact cards from `weakTopicsProvider`. Show topic name + days stuck.

```dart
class _WeakSpots extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final weakAsync = ref.watch(weakTopicsProvider(paperId));

    return weakAsync.when(
      data: (topics) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⚠️  Weak Spots', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...topics.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 10),
                    Text(t['name'], style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text('Stuck ${t['days']} days', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

### 4. Mock test trend — `_MockTrendChart`
Line chart using fl_chart with lavender line. X-axis = test index, Y-axis = percentage. Empty state: "Add your first mock test to see trends!".

```dart
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: points,
        color: AppColors.lavenderPurple,
        barWidth: 3,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: true, color: AppColors.lavenderPurple.withValues(alpha: 0.1)),
      ),
    ],
    borderData: FlBorderData(show: false),
    gridData: const FlGridData(show: false),
  ),
)
```

## Verification
- Bar chart shows lavender bars for each day of the week.
- Syllabus progress has one `GlassCard` per paper with `StatsRing`.
- Weak spots cards show "Stuck X days" with warning icon.
- Mock trend line chart renders with lavender line and transparent fill.
- Empty states show friendly messages instead of charts.
