import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paper.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/topic_progress.dart';
import '../models/study_session.dart';
import '../models/mock_test.dart';
import '../models/topic_note.dart';
import '../models/topic_revision.dart';
import '../services/database_helper.dart';

// --- Database Provider ---
final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

// --- Selected Paper Provider (default to ECE) ---
final selectedPaperIdProvider = StateProvider<int>((ref) => 2);

// --- Paper Providers ---
final allPapersProvider = FutureProvider<List<Paper>>((ref) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getAllPapers();
});

// --- Subject Providers ---
final subjectsByPaperProvider = FutureProvider.family<List<Subject>, int>((ref, paperId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getSubjectsByPaper(paperId);
});

// --- Subject Progress Provider (Completed / Total Topics) ---
final subjectProgressProvider = FutureProvider.family<Map<String, int>, int>((ref, subjectId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final topics = await dbHelper.getTopicsBySubject(subjectId);
  int completed = 0;
  for (final t in topics) {
    final prog = await dbHelper.getProgress(t.id!);
    if (prog?.status == ProgressStatus.completed) {
      completed++;
    }
  }
  return {
    'completed': completed,
    'total': topics.length,
  };
});

// --- Topic Providers ---
final topicsBySubjectProvider = FutureProvider.family<List<Topic>, int>((ref, subjectId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getTopicsBySubject(subjectId);
});

// --- Topic Progress Provider ---
final topicProgressProvider = StateNotifierProvider.family<TopicProgressNotifier, ProgressStatus, int>((ref, topicId) {
  return TopicProgressNotifier(topicId, ref);
});

class TopicProgressNotifier extends StateNotifier<ProgressStatus> {
  final int topicId;
  final Ref ref;

  TopicProgressNotifier(this.topicId, this.ref) : super(ProgressStatus.pending) {
    _load();
  }

  Future<void> _load() async {
    final dbHelper = ref.read(databaseHelperProvider);
    final progress = await dbHelper.getProgress(topicId);
    state = progress?.status ?? ProgressStatus.pending;
  }

  Future<void> toggle({required int subjectId, required int paperId}) async {
    // Simple 2-state toggle: pending ↔ completed
    final nextStatus = state == ProgressStatus.pending
        ? ProgressStatus.completed
        : ProgressStatus.pending;

    state = nextStatus;
    final dbHelper = ref.read(databaseHelperProvider);
    await dbHelper.setProgress(topicId, nextStatus);

    // Schedule 1st revision if marked as completed
    if (nextStatus == ProgressStatus.completed) {
      final revision = TopicRevision(
        topicId: topicId,
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        intervalDays: 1,
      );
      await dbHelper.addRevision(revision);
    }

    // Invalidate related providers
    ref.invalidate(subjectProgressProvider(subjectId));
    ref.invalidate(aggregateProgressProvider(paperId));
    ref.invalidate(weakTopicsProvider(paperId));
  }
}

// --- Topic Notes Provider ---
final topicNotesProvider = FutureProvider.family<List<TopicNote>, int>((ref, topicId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getNotesForTopic(topicId);
});

final topicNoteCountProvider = FutureProvider.family<int, int>((ref, topicId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getNoteCountForTopic(topicId);
});

// --- Study Session Providers ---
final studySessionsForTopicProvider = FutureProvider.family<List<StudySession>, int>((ref, topicId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getSessionsForTopic(topicId);
});

final studyHoursPerDayProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getStudyHoursPerDay(days: days);
});

// --- Mock Test Providers ---
final mockTestsByPaperProvider = FutureProvider.family<List<MockTest>, int>((ref, paperId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getMockTestsByPaper(paperId);
});

// --- Analytics Providers ---
final aggregateProgressProvider = FutureProvider.family<double, int>((ref, paperId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getAggregateProgress(paperId);
});

final weakTopicsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, paperId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getWeakTopics(paperId);
});

// --- Calendar Providers ---
/// Provider for events on a specific date. Uses a string key "yyyy-MM-dd"
final calendarDayEventsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, dateStr) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final date = DateTime.parse(dateStr);
  
  final studySessions = await dbHelper.getStudySessionsOnDateWithDetails(date);
  final completedTopics = await dbHelper.getCompletedTopicsOnDate(date);
  final mockTests = await dbHelper.getMockTestsOnDate(date);
  final revisions = await dbHelper.getPendingRevisionsOnDate(date);
  final scheduledEvents = await dbHelper.getPendingScheduledEventsOnDate(date);
  
  return {
    'studySessions': studySessions,
    'completedTopics': completedTopics,
    'mockTests': mockTests,
    'revisions': revisions,
    'scheduledEvents': scheduledEvents,
  };
});

// --- Heatmap Provider ---
final activityHeatmapProvider = FutureProvider.family<Map<DateTime, int>, DateTime>((ref, startDate) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return await dbHelper.getActivityHeatmapData(startDate);
});

/// Provider for event markers across a month range. Key: "yyyy-MM-dd|yyyy-MM-dd"
final calendarEventMarkersProvider = FutureProvider.family<Map<String, List<String>>, String>((ref, rangeKey) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final parts = rangeKey.split('|');
  final start = DateTime.parse(parts[0]);
  final end = DateTime.parse(parts[1]);
  return await dbHelper.getEventDatesInRange(start, end);
});
