# Step 09 — Mock Test Screen

## Goal
Display mock test history with a visual card layout — large score fraction, lavender percentage bar, clean date formatting, no tables.

## Layout

```
┌──────────────────────────────┐
│  Mock Tests        [+ Add]  │
│                              │
│  ┌──────────────────────────┐│
│  │ GATE 2025 CSE            ││  ← GlassCard
│  │ March 18, 2025           ││
│  │                          ││
│  │  42 / 100                ││  ← Large fraction (titleLarge)
│  │  ████████░░░░ 72%       ││  ← Thin lavender bar
│  │                          ││
│  │ Percentile: 94.2         ││  ← Small label
│  │ Rank: 1520               ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ AIMT-3 CSE               ││
│  │ February 10, 2025        ││
│  │                          ││
│  │  38 / 100                ││
│  │  ████████░░░░ 65%       ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

## Implementation

### File: `lib/screens/mock_test_screen.dart`

```dart
class MockTestScreen extends ConsumerWidget {
  const MockTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final testsAsync = ref.watch(mockTestsByPaperProvider(paperId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mock Tests', style: Theme.of(context).textTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded),
                    color: AppColors.lavenderPurple,
                    iconSize: 32,
                    onPressed: () => _showAddTestSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: testsAsync.when(
                data: (tests) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: tests.map((t) => _TestCard(context, t)).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _TestCard(BuildContext context, MockTest test) {
    final percentage = test.totalMarks > 0 ? test.marksObtained / test.totalMarks : 0.0;
    final dateFormatted = DateFormat('MMMM dd, yyyy').format(test.date);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(test.testName, style: Theme.of(context).textTheme.titleLarge),
              Text(dateFormatted, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${test.marksObtained}', style: Theme.of(context).textTheme.headlineLarge),
              Text(' / ${test.totalMarks}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: AppColors.lightGray,
              valueColor: const AlwaysStoppedAnimation(AppColors.lavenderPurple),
            ),
          ),
          const SizedBox(height: 8),
          if (test.percentile != null)
            Text('Percentile: ${test.percentile}', style: Theme.of(context).textTheme.bodyMedium),
          if (test.rank != null)
            Text('Rank: ${test.rank}', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showAddTestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => const _AddTestForm(),
    );
  }
}
```

### Add test form (`_AddTestForm`)
A bottom sheet with:
- Test name (TextField)
- Date (date picker)
- Total marks / Marks obtained (number inputs)
- Percentile / Rank (optional)
- Save button → calls `addMockTestProvider`

### Delete
Swipe-to-delete with confirmation and undo snackbar.

## Verification
- Mock tests render as floating cards with large fraction (`42 / 100`).
- A thin lavender bar shows percentage below the fraction.
- Date uses full month format ("March 18, 2025").
- Adding a test appends a new card to the list.
- Deleting shows undo snackbar.
