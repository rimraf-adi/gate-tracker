# Step 04 — Provider Layer

## Goal
Set up Riverpod state management providers that bridge the database layer to the UI.

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
dev_dependencies:
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.0
```

## Providers

### File: `lib/providers/providers.dart` (or split per domain)

```dart
// -- Database provider (async singleton)
final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseHelper.instance.database;
});

// -- Paper providers
final allPapersProvider = FutureProvider<List<Paper>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return DatabaseHelper.instance.getAllPapers();
});

// -- Subject providers
final subjectsByPaperProvider = FutureProvider.family<List<Subject>, int>(
  (ref, paperId) async { ... }
);

// -- Topic providers
final topicsBySubjectProvider = FutureProvider.family<List<Topic>, int>(
  (ref, subjectId) async { ... }
);

// -- Progress providers (Notifier)
final topicProgressProvider =
    StateNotifierProvider.family<TopicProgressNotifier, ProgressStatus, int>(
  (ref, topicId) => TopicProgressNotifier(topicId),
);

class TopicProgressNotifier extends StateNotifier<ProgressStatus> {
  TopicProgressNotifier(this.topicId) : super(ProgressStatus.notStarted) {
    _load();
  }
  final int topicId;
  Future<void> _load() async { ... }
  Future<void> toggle() async { ... }
}

// -- Study session provider
final studySessionsForTopicProvider =
    FutureProvider.family<List<StudySession>, int>((ref, topicId) async { ... });

final addStudySessionProvider = FutureProvider.family<void, StudySession>(
  (ref, session) async { ... }
);

// -- Mock test providers
final mockTestsByPaperProvider =
    FutureProvider.family<List<MockTest>, int>((ref, paperId) async { ... });

final addMockTestProvider = FutureProvider.family<void, MockTest>(
  (ref, test) async { ... }
);

// -- Analytics providers
final aggregateProgressProvider =
    FutureProvider.family<double, int>((ref, paperId) async { ... });

final studyHoursPerDayProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>(
  (ref, days) async { ... }
);

final weakTopicsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>(
  (ref, paperId) async { ... }
);
```

### Auto-refresh pattern
When `addStudySessionProvider` or `topicProgressProvider` completes, invalidate related providers so the UI rebuilds:
```dart
ref.invalidate(studySessionsForTopicProvider(topicId));
ref.invalidate(aggregateProgressProvider(paperId));
```

## Verification
- Write a simple widget test that uses `ProviderScope` and verifies a provider returns data.
- `flutter analyze` passes.
