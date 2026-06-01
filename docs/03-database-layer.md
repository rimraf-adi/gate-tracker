# Step 03 — Database Layer

## Goal
Implement a singleton `DatabaseHelper` class that manages the SQLite database connection and provides CRUD methods for all entities.

## Implementation

### File: `lib/services/database_helper.dart`

```dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gate_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filename) async { ... }
  Future<void> _onCreate(Database db, int version) async { ... }
}
```

### Schema creation (`_onCreate`)
Run all `CREATE TABLE` statements from Step 01 inside a batch.

### Required CRUD Methods

| Entity | Methods |
|---|---|
| Paper | `getAllPapers()`, `getPaperById(int id)`, `insertPaper(Paper p)`, `updatePaper(Paper p)`, `deletePaper(int id)` |
| Subject | `getSubjectsByPaper(int paperId)`, `getSubjectById(int id)`, `insertSubject(Subject s)`, `updateSubject(Subject s)`, `deleteSubject(int id)`, `reorderSubjects(List<int> ids)` |
| Topic | `getTopicsBySubject(int subjectId)`, `getTopicById(int id)`, `countTopicsBySubject(int subjectId)`, `insertTopic(Topic t)`, `updateTopic(Topic t)`, `deleteTopic(int id)`, `reorderTopics(List<int> ids)` |
| TopicProgress | `getProgress(int topicId)`, `setProgress(int topicId, ProgressStatus status)`, `resetAllProgress()`, `deleteProgressForTopic(int topicId)` |
| StudySession | `addSession(StudySession s)`, `getSessionsForTopic(int topicId)`, `getSessionsBetween(DateTime from, DateTime to)`, `deleteSessionsForTopic(int topicId)` |
| MockTest | `addMockTest(MockTest t)`, `getMockTestsByPaper(int paperId)`, `updateMockTest(MockTest t)`, `deleteMockTest(int id)` |
| MockTestSubjectBreakdown | `addBreakdown(...)`, `getBreakdownsForTest(int mockTestId)`, `deleteBreakdownsForTest(int mockTestId)` |

### Query helpers (for analytics)

```dart
Future<int> countTopicsByStatus(int paperId, ProgressStatus status);
Future<List<Map<String, dynamic>>> getStudyHoursPerDay({int days});
Future<double> getAggregateProgress(int paperId);
Future<List<Map<String, dynamic>>> getWeakTopics(int paperId); // in_progress > 7 days
```

### Cascade delete helper
When deleting a paper:
1. Delete all `mock_test_subject_breakdown` for that paper's mock tests
2. Delete all `mock_tests` for that paper
3. Delete all `study_sessions` for that paper's topics
4. Delete all `topic_progress` for that paper's topics
5. Delete all `topics` for that paper's subjects
6. Delete all `subjects` for that paper
7. Delete the `paper`

Call this in a single transaction.

## Database versioning
Start with version `1`. The `_onUpgrade` callback can handle schema migrations in future versions.

## Verification
- Unit tests for each CRUD method.
- Verify `getAllPapers()` returns both CSE and ECE after seeding.
- Verify `countTopicsByStatus` returns correct counts.
- Insert a custom paper, then delete it; verify cascade deletes all related rows.
