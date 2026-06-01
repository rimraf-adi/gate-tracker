# Step 06 — Dashboard Screen

## Goal
Build the dashboard — a visual-first home screen with oversized date, greeting, filter pills, and exam cards showing countdowns. No text-based stats tables.

## Layout

```
┌──────────────────────────────┐
│  ░░░░░░░░░░░░░░░░░░░░░░░░░  │  ← GradientBackground
│                              │
│  14                           │  ← Oversized date (48px bold)
│  June    Saturday             │
│                              │
│  Hey Aditya 👋               │  ← Greeting (24px medium)
│                              │
│  ┌──────┐ ┌────────┐ ┌─────┐│
│  │ All  │ │In-Progress│Done││  ← Filter pills (selected=lavender)
│  └──────┘ └────────┘ └─────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ Operating Systems        ││  ← GlassCard
│  │ ⏰ 09:00 AM              ││
│  │                          ││
│  │   ❗ 2 Days Left         ││  ← Lavender urgency badge
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ Computer Networks        ││
│  │ ⏰ 02:00 PM              ││
│  │                          ││
│  │   ❗ 5 Days Left         ││
│  └──────────────────────────┘│
│                              │
│   (bottom padding for nav)   │
│                              │
│       ╭─────────────╮        │
│       Home  Exams  Progress │
│       ╰─────────────╯        │
└──────────────────────────────┘
```

## Implementation

### File: `lib/screens/dashboard_screen.dart`

```dart
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    // TODO: load subjects/topics for countdown data

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          children: [
            const DateHeader(),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Hey Aditya 👋', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 20),
            const _FilterPills(),
            const SizedBox(height: 16),
            _ExamCard(context, 'Operating Systems', '09:00 AM', 2),
            _ExamCard(context, 'Computer Networks', '02:00 PM', 5),
          ],
        ),
      ),
    );
  }

  Widget _ExamCard(BuildContext context, String title, String time, int daysLeft) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(time, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lavenderPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text('$daysLeft Days Left',
              style: const TextStyle(color: AppColors.lavenderPurple, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Filter pills widget — `lib/widgets/filter_pills.dart`

```dart
class FilterPills extends StatefulWidget {
  @override
  State<FilterPills> createState() => _FilterPillsState();
}

class _FilterPillsState extends State<FilterPills> {
  int _selected = 0;
  final _filters = ['All', 'In Progress', 'Done'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _filters.map((f) {
          final idx = _filters.indexOf(f);
          final selected = idx == _selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? AppColors.lavenderPurple : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => setState(() => _selected = idx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Text(f,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

## Verification
- Dashboard shows oversized date `14` / `June` / `Saturday` as the hero.
- Filter pills are tappable, selected one turns lavender.
- Exam cards show time and a lavender "X Days Left" badge.
- Scrolling works, bottom nav stays visible.
- No table-style stats or progress bars on the dashboard.
