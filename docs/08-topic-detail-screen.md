# Step 08 — Topic Detail Screen

## Goal
Show all topics under a subject with a visual progress ring, tappable progress grid (checkmark circles), and a pill-shaped study logger button.

## Layout

```
┌──────────────────────────────┐
│  ← Engineering Mathematics   │
│                              │
│  Discrete Mathematics        │  ← Subject name as subtitle
│                              │
│       12/20 topics           │
│         ⭕ 60%               │  ← Large StatsRing
│                              │
│  [➕ Log Study Session]      │  ← ActionButton (lavender pill)
│                              │
│  ┌──────────────────────────┐│
│  │ ✓  Propositional Logic  ││  ← ProgressGrid
│  │ ✓  Sets, relations      ││     Lavender circle = completed
│  │ ◌  Functions            ││     Grey circle = not started
│  │ ◌  Partial orders       ││     Orange dot  = in progress
│  │ ◌  Monoids              ││
│  │ ◌  Groups               ││
│  │ ✓  Graphs: connectivity ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

## Implementation

### File: `lib/screens/topic_detail_screen.dart`

```dart
class TopicDetailScreen extends ConsumerWidget {
  final int subjectId;

  const TopicDetailScreen({required this.subjectId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsBySubjectProvider(subjectId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Back + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Engineering Mathematics',
                      style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Discrete Mathematics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
            ),
            const SizedBox(height: 20),
            // Progress ring
            Center(
              child: Column(
                children: [
                  const StatsRing(progress: 0.6, size: 80),
                  const SizedBox(height: 6),
                  Text('12/20 topics', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Log study button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ActionButton(
                label: 'Log Study Session',
                icon: Icons.add_rounded,
                onTap: () => _showLogStudySheet(context),
              ),
            ),
            const SizedBox(height: 20),
            // Topic grid
            Expanded(
              child: topicsAsync.when(
                data: (topics) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: topics.map((topic) => ProgressGridItem(
                    label: topic.name,
                    completed: false, // TODO: read from topicProgressProvider
                    status: ProgressStatus.notStarted,
                    onTap: () {
                      ref.read(topicProgressProvider(topic.id).notifier).toggle();
                    },
                  )).toList(),
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

  void _showLogStudySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log Study Session', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            // Duration picker (15/30/45/60/90/120 chips)
            // Confirm button
          ],
        ),
      ),
    );
  }
}
```

### Progress grid
Use the `ProgressGrid` widget from Step 15's design system. Wrap each row in a `Material` with lavender background when completed.

### Status toggling
Tapping a topic row cycles the status via `topicProgressProvider(topicId).notifier.toggle()`. The filled circle visually reflects the state.

## Verification
- Large progress ring at top center shows completion percentage.
- Topic rows show filled lavender circle for completed, grey for not started.
- Tapping a topic cycles the status and updates the ring.
- "Log Study Session" button is a lavender pill, opens a bottom sheet.
