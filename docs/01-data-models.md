# Step 01 — Data Models & SQLite Schema

## Goal
Define all Dart data model classes and the corresponding SQLite table schemas.

## Models

### 1. `Paper`
Represents an exam paper (e.g. CSE, ECE, or a custom user-created exam).

```dart
class Paper {
  final int id;
  final String code;            // "CSE", "ECE", "CUSTOM-001"
  final String fullName;        // "Computer Science & Information Technology"
  final bool isCustom;          // true for user-created exams
  final String? syllabusSource; // raw syllabus text for custom exams; null for built-in
  final int sortOrder;          // ordering in the paper selector
}
```

**Schema:**
```sql
CREATE TABLE papers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  is_custom INTEGER NOT NULL DEFAULT 0,
  syllabus_source TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0
);
```

### 2. `Subject`
Maps to a Section in the syllabus (e.g. "Engineering Mathematics").

```dart
class Subject {
  final int id;
  final int paperId;
  final String name;       // "Engineering Mathematics"
  final int sortOrder;     // section ordering
}
```

**Schema:**
```sql
CREATE TABLE subjects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  paper_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (paper_id) REFERENCES papers(id)
);
```

### 3. `Topic`
A leaf-level item within a subject (e.g. "Discrete Mathematics: Propositional and first order logic").

```dart
class Topic {
  final int id;
  final int subjectId;
  final String name;
  final int sortOrder;
}
```

**Schema:**
```sql
CREATE TABLE topics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  subject_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (subject_id) REFERENCES subjects(id)
);
```

### 4. `TopicProgress`

```dart
enum ProgressStatus { notStarted, inProgress, completed }

class TopicProgress {
  final int id;
  final int topicId;
  final ProgressStatus status;
  final DateTime? lastUpdated;
}
```

**Schema:**
```sql
CREATE TABLE topic_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  topic_id INTEGER NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'notStarted',
  last_updated TEXT,
  FOREIGN KEY (topic_id) REFERENCES topics(id)
);
```

### 5. `StudySession`

```dart
class StudySession {
  final int id;
  final int topicId;
  final DateTime date;
  final int durationMinutes; // in minutes
}
```

**Schema:**
```sql
CREATE TABLE study_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  topic_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  FOREIGN KEY (topic_id) REFERENCES topics(id)
);
```

### 6. `MockTest`

```dart
class MockTest {
  final int id;
  final int paperId;
  final String testName;
  final DateTime date;
  final int totalMarks;
  final int marksObtained;
  final double? percentile;
  final int? rank;
}
```

**Schema:**
```sql
CREATE TABLE mock_tests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  paper_id INTEGER NOT NULL,
  test_name TEXT NOT NULL,
  date TEXT NOT NULL,
  total_marks INTEGER NOT NULL,
  marks_obtained INTEGER NOT NULL,
  percentile REAL,
  rank_value INTEGER,
  FOREIGN KEY (paper_id) REFERENCES papers(id)
);
```

### 7. `MockTestSubjectBreakdown`

```dart
class MockTestSubjectBreakdown {
  final int id;
  final int mockTestId;
  final int subjectId;
  final int marksObtained;
  final int totalMarks;
}
```

**Schema:**
```sql
CREATE TABLE mock_test_subject_breakdown (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  mock_test_id INTEGER NOT NULL,
  subject_id INTEGER NOT NULL,
  marks_obtained INTEGER NOT NULL,
  total_marks INTEGER NOT NULL,
  FOREIGN KEY (mock_test_id) REFERENCES mock_tests(id),
  FOREIGN KEY (subject_id) REFERENCES subjects(id)
);
```

## Actions
1. Create `lib/models/` directory.
2. Create each model file inside `lib/models/`.
3. All models should have `toMap()` and `fromMap()` factory methods.
4. Add `copyWith()` for mutable fields.

## Verification
- Run `flutter analyze` — zero errors.
- All `toMap()` / `fromMap()` round-trip correctly in a unit test.
