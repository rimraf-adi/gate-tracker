# Step 07 — Subject List Screen (Exams Tab)

## Goal
Display all subjects (sections) for a given paper as premium floating cards with a circular progress ring instead of a linear progress bar.

## Layout

```
┌──────────────────────────────┐
│  ←  Subjects                 │
│                              │
│  ┌──────────────────────────┐│
│  │ 📐  Engineering Math     ││  ← GlassCard
│  │     12/20 topics         ││
│  │                ⭕ 60%    ││  ← StatsRing
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ 💻  Digital Logic        ││
│  │     8/20 topics          ││
│  │                ⭕ 40%    ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ 🖥️  Computer Org        ││
│  │     16/20 topics         ││
│  │                ⭕ 80%    ││
│  └──────────────────────────┘│
│                              │
│       ╭─────────────╮        │
│       Home  Exams  Progress │
│       ╰─────────────╯        │
└──────────────────────────────┘
```

## Implementation

### File: `lib/screens/subject_list_screen.dart`

```dart
class SubjectListScreen extends ConsumerWidget {
  const SubjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final subjectsAsync = ref.watch(subjectsByPaperProvider(paperId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Subjects', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 8),
            // Paper selector chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _PaperChip(paperId: paperId),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) => ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: subjects.length,
                  itemBuilder: (_, i) => _SubjectCard(context, subjects[i]),
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

  Widget _SubjectCard(BuildContext context, Subject subject) {
    // TODO: load topic count and completed count for this subject
    final totalTopics = 20; // placeholder
    final completedTopics = 12; // placeholder
    final progress = totalTopics > 0 ? completedTopics / totalTopics : 0.0;

    return GlassCard(
      onTap: () => Navigator.pushNamed(context, '/topics', arguments: subject.id),
      child: Row(
        children: [
          Text(_emojiFor(subject.name), style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('$completedTopics/$totalTopics topics',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          StatsRing(progress: progress),
        ],
      ),
    );
  }

  String _emojiFor(String name) {
    if (name.contains('Math')) return '📐';
    if (name.contains('Digital')) return '💻';
    if (name.contains('Computer Org') || name.contains('Architecture')) return '🖥️';
    if (name.contains('Program') || name.contains('Data Structure')) return '👨‍💻';
    if (name.contains('Algo')) return '⚙️';
    if (name.contains('Theory') || name.contains('TOC')) return '🔬';
    if (name.contains('Compiler')) return '🔧';
    if (name.contains('Operating') || name.contains('OS')) return '⚡';
    if (name.contains('Database') || name.contains('DB')) return '🗄️';
    if (name.contains('Network')) return '🌐';
    if (name.contains('Signal') || name.contains('Network')) return '📡';
    if (name.contains('Device') || name.contains('Electron')) return '🔌';
    if (name.contains('Analog')) return '⚡';
    if (name.contains('Control')) return '🎛️';
    if (name.contains('Comm')) return '📶';
    if (name.contains('Electromag')) return '🧲';
    return '📖';
  }
}
```

### Paper chip widget — `lib/widgets/paper_chip.dart`
A small pill that shows the selected paper name and opens a dropdown to switch.

## Verification
- All subjects render as floating white cards with 24px radius.
- Each card has a circular progress ring (StatsRing) on the right.
- Emoji appears on the left of each card.
- Tapping a card navigates to `/topics`.
- Switching the paper (via chip dropdown) updates the subject list.
