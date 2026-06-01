import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/paper.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/topic_progress.dart';
import '../models/study_session.dart';
import '../models/mock_test.dart';
import '../models/mock_test_subject_breakdown.dart';
import '../models/topic_note.dart';
import '../models/topic_revision.dart';
import '../models/scheduled_event.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gate_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE topics ADD COLUMN chapter TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 3) {
      // Migrate inProgress/notStarted → pending
      await db.execute("UPDATE topic_progress SET status = 'pending' WHERE status IN ('notStarted', 'inProgress')");
      // Create topic_notes table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS topic_notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          topic_id INTEGER NOT NULL,
          content TEXT NOT NULL DEFAULT '',
          image_path TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS topic_revisions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          topic_id INTEGER NOT NULL,
          scheduled_date TEXT NOT NULL,
          completed_date TEXT,
          interval_days INTEGER NOT NULL,
          FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scheduled_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          topic_id INTEGER NOT NULL,
          scheduled_date TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE topic_progress ADD COLUMN manual_strength TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE papers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        syllabus_source TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paper_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        chapter TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE topic_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'pending',
        last_updated TEXT,
        manual_strength TEXT,
        FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE mock_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paper_id INTEGER NOT NULL,
        test_name TEXT NOT NULL,
        date TEXT NOT NULL,
        total_marks INTEGER NOT NULL,
        marks_obtained INTEGER NOT NULL,
        percentile REAL,
        rank_value INTEGER,
        FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE mock_test_subject_breakdown (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mock_test_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        marks_obtained INTEGER NOT NULL,
        total_marks INTEGER NOT NULL,
        FOREIGN KEY (mock_test_id) REFERENCES mock_tests(id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE topic_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE topic_revisions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        scheduled_date TEXT NOT NULL,
        completed_date TEXT,
        interval_days INTEGER NOT NULL,
        FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scheduled_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        scheduled_date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- PAPER CRUD ---
  Future<List<Paper>> getAllPapers() async {
    final db = await instance.database;
    final result = await db.query('papers', orderBy: 'sort_order ASC');
    return result.map((json) => Paper.fromMap(json)).toList();
  }

  Future<Paper?> getPaperById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'papers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Paper.fromMap(result.first);
    }
    return null;
  }

  Future<Paper?> getPaperByCode(String code) async {
    final db = await instance.database;
    final result = await db.query(
      'papers',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (result.isNotEmpty) {
      return Paper.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertPaper(Paper paper) async {
    final db = await instance.database;
    return await db.insert('papers', paper.toMap());
  }

  Future<int> updatePaper(Paper paper) async {
    final db = await instance.database;
    return await db.update(
      'papers',
      paper.toMap(),
      where: 'id = ?',
      whereArgs: [paper.id],
    );
  }

  Future<void> deletePaper(int id) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final mockTestRows = await txn.query('mock_tests', columns: ['id'], where: 'paper_id = ?', whereArgs: [id]);
      final mockTestIds = mockTestRows.map((r) => r['id'] as int).toList();
      for (final testId in mockTestIds) {
        await txn.delete('mock_test_subject_breakdown', where: 'mock_test_id = ?', whereArgs: [testId]);
      }
      await txn.delete('mock_tests', where: 'paper_id = ?', whereArgs: [id]);

      final subjectRows = await txn.query('subjects', columns: ['id'], where: 'paper_id = ?', whereArgs: [id]);
      final subjectIds = subjectRows.map((r) => r['id'] as int).toList();
      
      for (final subjectId in subjectIds) {
        final topicRows = await txn.query('topics', columns: ['id'], where: 'subject_id = ?', whereArgs: [subjectId]);
        final topicIds = topicRows.map((r) => r['id'] as int).toList();
        for (final topicId in topicIds) {
          await txn.delete('study_sessions', where: 'topic_id = ?', whereArgs: [topicId]);
          await txn.delete('topic_progress', where: 'topic_id = ?', whereArgs: [topicId]);
          await txn.delete('topic_notes', where: 'topic_id = ?', whereArgs: [topicId]);
        }
        await txn.delete('topics', where: 'subject_id = ?', whereArgs: [subjectId]);
      }
      await txn.delete('subjects', where: 'paper_id = ?', whereArgs: [id]);
      await txn.delete('papers', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- SUBJECT CRUD ---
  Future<List<Subject>> getSubjectsByPaper(int paperId) async {
    final db = await instance.database;
    final result = await db.query(
      'subjects',
      where: 'paper_id = ?',
      whereArgs: [paperId],
      orderBy: 'sort_order ASC',
    );
    return result.map((json) => Subject.fromMap(json)).toList();
  }

  Future<Subject?> getSubjectById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Subject.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertSubject(Subject subject) async {
    final db = await instance.database;
    return await db.insert('subjects', subject.toMap());
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await instance.database;
    return await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<void> deleteSubject(int id) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final topicRows = await txn.query('topics', columns: ['id'], where: 'subject_id = ?', whereArgs: [id]);
      final topicIds = topicRows.map((r) => r['id'] as int).toList();
      for (final topicId in topicIds) {
        await txn.delete('study_sessions', where: 'topic_id = ?', whereArgs: [topicId]);
        await txn.delete('topic_progress', where: 'topic_id = ?', whereArgs: [topicId]);
        await txn.delete('topic_notes', where: 'topic_id = ?', whereArgs: [topicId]);
      }
      await txn.delete('topics', where: 'subject_id = ?', whereArgs: [id]);
      await txn.delete('mock_test_subject_breakdown', where: 'subject_id = ?', whereArgs: [id]);
      await txn.delete('subjects', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> reorderSubjects(List<int> ids) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      for (var i = 0; i < ids.length; i++) {
        await txn.update(
          'subjects',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [ids[i]],
        );
      }
    });
  }

  // --- TOPIC CRUD ---
  Future<List<Topic>> getTopicsBySubject(int subjectId) async {
    final db = await instance.database;
    final result = await db.query(
      'topics',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'sort_order ASC',
    );
    return result.map((json) => Topic.fromMap(json)).toList();
  }

  Future<Topic?> getTopicById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'topics',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Topic.fromMap(result.first);
    }
    return null;
  }

  Future<int> countTopicsBySubject(int subjectId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM topics WHERE subject_id = ?',
      [subjectId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertTopic(Topic topic) async {
    final db = await instance.database;
    return await db.insert('topics', topic.toMap());
  }

  Future<int> updateTopic(Topic topic) async {
    final db = await instance.database;
    return await db.update(
      'topics',
      topic.toMap(),
      where: 'id = ?',
      whereArgs: [topic.id],
    );
  }

  Future<void> deleteTopic(int id) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('study_sessions', where: 'topic_id = ?', whereArgs: [id]);
      await txn.delete('topic_progress', where: 'topic_id = ?', whereArgs: [id]);
      await txn.delete('topic_notes', where: 'topic_id = ?', whereArgs: [id]);
      await txn.delete('topics', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> reorderTopics(List<int> ids) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      for (var i = 0; i < ids.length; i++) {
        await txn.update(
          'topics',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [ids[i]],
        );
      }
    });
  }

  // --- TOPIC PROGRESS ---
  Future<TopicProgress?> getProgress(int topicId) async {
    final db = await instance.database;
    final result = await db.query(
      'topic_progress',
      where: 'topic_id = ?',
      whereArgs: [topicId],
    );
    if (result.isNotEmpty) {
      return TopicProgress.fromMap(result.first);
    }
    return null;
  }

  Future<void> setProgress(int topicId, ProgressStatus status, {String? manualStrength}) async {
    final db = await instance.database;
    final nowStr = DateTime.now().toIso8601String();
    await db.insert(
      'topic_progress',
      {
        'topic_id': topicId,
        'status': status.name,
        'last_updated': nowStr,
        if (manualStrength != null) 'manual_strength': manualStrength,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setManualStrength(int topicId, String? strength) async {
    final db = await instance.database;
    await db.insert(
      'topic_progress',
      {
        'topic_id': topicId,
        'status': 'pending',
        'manual_strength': strength,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> resetAllProgress() async {
    final db = await instance.database;
    await db.delete('topic_progress');
    await db.delete('study_sessions');
    await db.delete('topic_revisions');
    await db.delete('scheduled_events');
    await db.delete('mock_tests');
    await db.delete('mock_test_subject_breakdown');
  }

  Future<void> deleteProgressForTopic(int topicId) async {
    final db = await instance.database;
    await db.delete('topic_progress', where: 'topic_id = ?', whereArgs: [topicId]);
  }

  // --- TOPIC NOTES ---
  Future<List<TopicNote>> getNotesForTopic(int topicId) async {
    final db = await instance.database;
    final result = await db.query(
      'topic_notes',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => TopicNote.fromMap(json)).toList();
  }

  Future<int> getNoteCountForTopic(int topicId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM topic_notes WHERE topic_id = ?',
      [topicId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> addNote(TopicNote note) async {
    final db = await instance.database;
    return await db.insert('topic_notes', note.toMap());
  }

  Future<int> updateNote(TopicNote note) async {
    final db = await instance.database;
    return await db.update(
      'topic_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await instance.database;
    await db.delete('topic_notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- STUDY SESSION ---
  Future<int> addSession(StudySession session) async {
    final db = await instance.database;
    return await db.insert('study_sessions', session.toMap());
  }

  Future<List<StudySession>> getSessionsForTopic(int topicId) async {
    final db = await instance.database;
    final result = await db.query(
      'study_sessions',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'date DESC',
    );
    return result.map((json) => StudySession.fromMap(json)).toList();
  }

  Future<List<StudySession>> getSessionsBetween(DateTime from, DateTime to) async {
    final db = await instance.database;
    final result = await db.query(
      'study_sessions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'date ASC',
    );
    return result.map((json) => StudySession.fromMap(json)).toList();
  }

  Future<void> deleteSessionsForTopic(int topicId) async {
    final db = await instance.database;
    await db.delete('study_sessions', where: 'topic_id = ?', whereArgs: [topicId]);
  }

  // --- CALENDAR QUERIES ---
  Future<List<StudySession>> getStudySessionsOnDate(DateTime date) async {
    final db = await instance.database;
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final result = await db.rawQuery('''
      SELECT ss.*, t.name as topic_name, s.name as subject_name
      FROM study_sessions ss
      JOIN topics t ON ss.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE substr(ss.date, 1, 10) = ?
      ORDER BY ss.date DESC
    ''', [dateStr]);
    return result.map((json) => StudySession.fromMap(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getStudySessionsOnDateWithDetails(DateTime date) async {
    final db = await instance.database;
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final result = await db.rawQuery('''
      SELECT ss.*, t.name as topic_name, s.name as subject_name
      FROM study_sessions ss
      JOIN topics t ON ss.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE substr(ss.date, 1, 10) = ?
      ORDER BY ss.date DESC
    ''', [dateStr]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getCompletedTopicsOnDate(DateTime date) async {
    final db = await instance.database;
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final result = await db.rawQuery('''
      SELECT t.id, t.name as topic_name, s.name as subject_name, tp.last_updated
      FROM topic_progress tp
      JOIN topics t ON tp.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE tp.status = 'completed' AND substr(tp.last_updated, 1, 10) = ?
      ORDER BY tp.last_updated DESC
    ''', [dateStr]);
    return result;
  }

  Future<List<MockTest>> getMockTestsOnDate(DateTime date) async {
    final db = await instance.database;
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final result = await db.rawQuery('''
      SELECT * FROM mock_tests
      WHERE substr(date, 1, 10) = ?
      ORDER BY date DESC
    ''', [dateStr]);
    return result.map((json) => MockTest.fromMap(json)).toList();
  }

  /// Returns a map of date strings (yyyy-MM-dd) to a list of event type strings
  /// for the given date range. Event types: 'study', 'completed', 'mock'
  Future<Map<String, List<String>>> getEventDatesInRange(DateTime start, DateTime end) async {
    final db = await instance.database;
    final startStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
    final endStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

    final Map<String, Set<String>> events = {};

    // Study sessions
    final studyRows = await db.rawQuery('''
      SELECT substr(date, 1, 10) as d FROM study_sessions
      WHERE substr(date, 1, 10) >= ? AND substr(date, 1, 10) <= ?
      GROUP BY d
    ''', [startStr, endStr]);
    for (final row in studyRows) {
      final d = row['d'] as String;
      events.putIfAbsent(d, () => {}).add('study');
    }

    // Completed topics
    final completedRows = await db.rawQuery('''
      SELECT substr(last_updated, 1, 10) as d FROM topic_progress
      WHERE status = 'completed' AND last_updated IS NOT NULL
      AND substr(last_updated, 1, 10) >= ? AND substr(last_updated, 1, 10) <= ?
      GROUP BY d
    ''', [startStr, endStr]);
    for (final row in completedRows) {
      final d = row['d'] as String;
      events.putIfAbsent(d, () => {}).add('completed');
    }

    // Mock tests
    final mockRows = await db.rawQuery('''
      SELECT substr(date, 1, 10) as d FROM mock_tests
      WHERE substr(date, 1, 10) >= ? AND substr(date, 1, 10) <= ?
      GROUP BY d
    ''', [startStr, endStr]);
    for (final row in mockRows) {
      final d = row['d'] as String;
      events.putIfAbsent(d, () => {}).add('mock');
    }

    // Revisions
    final revisionRows = await db.rawQuery('''
      SELECT substr(scheduled_date, 1, 10) as d FROM topic_revisions
      WHERE completed_date IS NULL
      AND substr(scheduled_date, 1, 10) >= ? AND substr(scheduled_date, 1, 10) <= ?
      GROUP BY d
    ''', [startStr, endStr]);
    for (final row in revisionRows) {
      final d = row['d'] as String;
      events.putIfAbsent(d, () => {}).add('revision');
    }

    // Scheduled events
    final scheduledRows = await db.rawQuery('''
      SELECT substr(scheduled_date, 1, 10) as d FROM scheduled_events
      WHERE is_completed = 0
      AND substr(scheduled_date, 1, 10) >= ? AND substr(scheduled_date, 1, 10) <= ?
      GROUP BY d
    ''', [startStr, endStr]);
    for (final row in scheduledRows) {
      final d = row['d'] as String;
      events.putIfAbsent(d, () => {}).add('scheduled');
    }

    return events.map((key, value) => MapEntry(key, value.toList()));
  }

  // --- REVISIONS ---
  Future<int> addRevision(TopicRevision revision) async {
    final db = await instance.database;
    return await db.insert('topic_revisions', revision.toMap());
  }

  Future<int> updateRevision(TopicRevision revision) async {
    final db = await instance.database;
    return await db.update(
      'topic_revisions',
      revision.toMap(),
      where: 'id = ?',
      whereArgs: [revision.id],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingRevisionsOnDate(DateTime date) async {
    final db = await instance.database;
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final result = await db.rawQuery('''
      SELECT r.*, t.name as topic_name, s.name as subject_name
      FROM topic_revisions r
      JOIN topics t ON r.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE substr(r.scheduled_date, 1, 10) <= ? AND r.completed_date IS NULL
      ORDER BY r.scheduled_date ASC
    ''', [dateStr]);
    return result;
  }

  // --- SCHEDULED EVENTS ---
  Future<int> addScheduledEvent(ScheduledEvent event) async {
    final db = await instance.database;
    return await db.insert('scheduled_events', event.toMap());
  }

  Future<int> updateScheduledEvent(ScheduledEvent event) async {
    final db = await instance.database;
    return await db.update(
      'scheduled_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteScheduledEvent(int id) async {
    final db = await instance.database;
    return await db.delete('scheduled_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPendingScheduledEventsOnDate(DateTime date) async {
    final db = await instance.database;
    final dateStr = _dateToStr(date);
    final result = await db.rawQuery('''
      SELECT e.*, t.name as topic_name, s.name as subject_name
      FROM scheduled_events e
      JOIN topics t ON e.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE substr(e.scheduled_date, 1, 10) = ? AND e.is_completed = 0
      ORDER BY e.id ASC
    ''', [dateStr]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getScheduledEventsInRange(DateTime start, DateTime end) async {
    final db = await instance.database;
    final startStr = _dateToStr(start);
    final endStr = _dateToStr(end);
    return await db.rawQuery('''
      SELECT e.*, t.name as topic_name, s.name as subject_name, p.code as paper_code,
             s.id as subject_id
      FROM scheduled_events e
      JOIN topics t ON e.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      JOIN papers p ON s.paper_id = p.id
      WHERE substr(e.scheduled_date, 1, 10) >= ? AND substr(e.scheduled_date, 1, 10) <= ?
      ORDER BY e.scheduled_date ASC, e.id ASC
    ''', [startStr, endStr]);
  }

  Future<List<Map<String, dynamic>>> getAllPendingScheduledWithDetails() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT e.*, t.name as topic_name, s.name as subject_name, p.code as paper_code,
             s.id as subject_id
      FROM scheduled_events e
      JOIN topics t ON e.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      JOIN papers p ON s.paper_id = p.id
      WHERE e.is_completed = 0
      ORDER BY e.scheduled_date ASC, e.id ASC
    ''');
  }

  Future<void> toggleScheduledEvent(int id, bool completed) async {
    final db = await instance.database;
    await db.update('scheduled_events', {'is_completed': completed ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  // --- HEATMAP ---
  Future<Map<DateTime, int>> getActivityHeatmapData(DateTime startDate) async {
    final db = await instance.database;
    final startStr = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final result = await db.rawQuery('''
      SELECT substr(date, 1, 10) as d, SUM(duration_minutes) as total_duration
      FROM study_sessions
      WHERE substr(date, 1, 10) >= ?
      GROUP BY d
    ''', [startStr]);

    final Map<DateTime, int> heatmapData = {};
    for (final row in result) {
      final dateParts = (row['d'] as String).split('-');
      final date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
      heatmapData[date] = (row['total_duration'] as int);
    }
    return heatmapData;
  }

  // --- MOCK TEST ---
  Future<int> addMockTest(MockTest test) async {
    final db = await instance.database;
    return await db.insert('mock_tests', test.toMap());
  }

  Future<List<MockTest>> getMockTestsByPaper(int paperId) async {
    final db = await instance.database;
    final result = await db.query(
      'mock_tests',
      where: 'paper_id = ?',
      whereArgs: [paperId],
      orderBy: 'date DESC',
    );
    return result.map((json) => MockTest.fromMap(json)).toList();
  }

  Future<int> updateMockTest(MockTest test) async {
    final db = await instance.database;
    return await db.update(
      'mock_tests',
      test.toMap(),
      where: 'id = ?',
      whereArgs: [test.id],
    );
  }

  Future<void> deleteMockTest(int id) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('mock_test_subject_breakdown', where: 'mock_test_id = ?', whereArgs: [id]);
      await txn.delete('mock_tests', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- BREAKDOWNS ---
  Future<int> addBreakdown(MockTestSubjectBreakdown breakdown) async {
    final db = await instance.database;
    return await db.insert('mock_test_subject_breakdown', breakdown.toMap());
  }

  Future<List<MockTestSubjectBreakdown>> getBreakdownsForTest(int mockTestId) async {
    final db = await instance.database;
    final result = await db.query(
      'mock_test_subject_breakdown',
      where: 'mock_test_id = ?',
      whereArgs: [mockTestId],
    );
    return result.map((json) => MockTestSubjectBreakdown.fromMap(json)).toList();
  }

  Future<void> deleteBreakdownsForTest(int mockTestId) async {
    final db = await instance.database;
    await db.delete('mock_test_subject_breakdown', where: 'mock_test_id = ?', whereArgs: [mockTestId]);
  }

  // --- ANALYTICS QUERIES ---
  Future<int> countTopicsByStatus(int paperId, ProgressStatus status) async {
    final db = await instance.database;

    if (status == ProgressStatus.pending) {
      // Pending = total - completed
      final totalResult = await db.rawQuery('''
        SELECT COUNT(*) as c
        FROM topics t
        JOIN subjects s ON t.subject_id = s.id
        WHERE s.paper_id = ?
      ''', [paperId]);
      final total = Sqflite.firstIntValue(totalResult) ?? 0;
      
      final completedResult = await db.rawQuery('''
        SELECT COUNT(*) as c
        FROM topics t
        JOIN subjects s ON t.subject_id = s.id
        JOIN topic_progress tp ON t.id = tp.topic_id
        WHERE s.paper_id = ? AND tp.status = 'completed'
      ''', [paperId]);
      final completed = Sqflite.firstIntValue(completedResult) ?? 0;
      return total - completed;
    }

    // status == completed
    final result = await db.rawQuery('''
      SELECT COUNT(*) as c 
      FROM topics t
      JOIN subjects s ON t.subject_id = s.id
      JOIN topic_progress tp ON t.id = tp.topic_id
      WHERE s.paper_id = ? AND tp.status = ?
    ''', [paperId, status.name]);
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getStudyHoursPerDay({int days = 7}) async {
    final db = await instance.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final result = await db.query(
      'study_sessions',
      columns: ['date', 'duration_minutes'],
      where: 'date >= ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    // Group by date in Dart
    final Map<String, int> grouped = {};
    for (final row in result) {
      final dateTime = DateTime.tryParse(row['date'] as String);
      if (dateTime != null) {
        final dateKey = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
        grouped[dateKey] = (grouped[dateKey] ?? 0) + (row['duration_minutes'] as int);
      }
    }

    final List<Map<String, dynamic>> output = [];
    for (var i = days - 1; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final dateKey = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      final duration = grouped[dateKey] ?? 0;
      output.add({
        'date': dateKey,
        'duration': duration,
        'weekday': d.weekday,
      });
    }

    return output;
  }

  Future<double> getAggregateProgress(int paperId) async {
    final db = await instance.database;
    
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as c
      FROM topics t
      JOIN subjects s ON t.subject_id = s.id
      WHERE s.paper_id = ?
    ''', [paperId]);
    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    if (total == 0) return 0.0;

    final completedResult = await db.rawQuery('''
      SELECT COUNT(*) as c
      FROM topics t
      JOIN subjects s ON t.subject_id = s.id
      JOIN topic_progress tp ON t.id = tp.topic_id
      WHERE s.paper_id = ? AND tp.status = 'completed'
    ''', [paperId]);
    final completed = Sqflite.firstIntValue(completedResult) ?? 0;

    return completed / total;
  }

  Future<List<Map<String, dynamic>>> getWeakTopics(int paperId) async {
    final db = await instance.database;
    // Weak topics: topics that have study sessions logged but are still pending,
    // and the most recent study session is older than 7 days
    final result = await db.rawQuery('''
      SELECT t.id, t.name, MAX(ss.date) as last_studied
      FROM topics t
      JOIN subjects s ON t.subject_id = s.id
      JOIN study_sessions ss ON t.id = ss.topic_id
      LEFT JOIN topic_progress tp ON t.id = tp.topic_id
      WHERE s.paper_id = ? AND (tp.status IS NULL OR tp.status = 'pending')
      GROUP BY t.id
    ''', [paperId]);

    final List<Map<String, dynamic>> weakTopics = [];
    final now = DateTime.now();

    for (final row in result) {
      final lastStudiedStr = row['last_studied'] as String?;
      if (lastStudiedStr != null) {
        final lastStudied = DateTime.tryParse(lastStudiedStr);
        if (lastStudied != null) {
          final diffDays = now.difference(lastStudied).inDays;
          if (diffDays >= 7) {
            weakTopics.add({
              'id': row['id'] as int,
              'name': row['name'] as String,
              'days': diffDays,
            });
          }
        }
      }
    }

    weakTopics.sort((a, b) => (b['days'] as int).compareTo(a['days'] as int));
    return weakTopics;
  }

  // --- HOME SCREEN METRICS ---

  Future<int> getCompletedTopicsCountToday() async {
    final db = await instance.database;
    final todayStr = _todayDateStr();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as c FROM topic_progress
      WHERE status = 'completed' AND substr(last_updated, 1, 10) = ?
    ''', [todayStr]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getScheduledEventsForTodayCount() async {
    final db = await instance.database;
    final todayStr = _todayDateStr();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as c FROM scheduled_events
      WHERE substr(scheduled_date, 1, 10) = ? AND is_completed = 0
    ''', [todayStr]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingRevisionsForTodayCount() async {
    final db = await instance.database;
    final todayStr = _todayDateStr();
    final result = await db.rawQuery('''
      SELECT COUNT(*) as c FROM topic_revisions
      WHERE completed_date IS NULL AND substr(scheduled_date, 1, 10) <= ?
    ''', [todayStr]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalStudyHoursAllTime() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(duration_minutes), 0) as t FROM study_sessions');
    final totalMin = Sqflite.firstIntValue(result) ?? 0;
    return totalMin;
  }

  Future<int> getCurrentStreak() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT substr(date, 1, 10) as d FROM study_sessions ORDER BY d DESC
    ''');
    final dates = result.map((r) => r['d'] as String).toList();
    if (dates.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    for (var i = 0; i < dates.length; i++) {
      final expected = today.subtract(Duration(days: i));
      final expectedStr = _dateToStr(expected);
      if (dates[i] == expectedStr) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> getCompletedSubjectsCount(int paperId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT s.id,
        (SELECT COUNT(*) FROM topics t WHERE t.subject_id = s.id) as total,
        (SELECT COUNT(*) FROM topics t
         JOIN topic_progress tp ON t.id = tp.topic_id AND tp.status = 'completed'
         WHERE t.subject_id = s.id) as done
      FROM subjects s WHERE s.paper_id = ?
    ''', [paperId]);

    int count = 0;
    for (final row in result) {
      final total = row['total'] as int? ?? 0;
      final done = row['done'] as int? ?? 0;
      if (total > 0 && done >= total) count++;
    }
    return count;
  }

  Future<int> getTotalNotesCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM topic_notes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getAverageMockScorePercentage(int paperId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(marks_obtained), 0) as obtained,
             COALESCE(SUM(total_marks), 0) as total
      FROM mock_tests WHERE paper_id = ?
    ''', [paperId]);
    if (result.isNotEmpty) {
      final obtained = (result.first['obtained'] as int?) ?? 0;
      final total = (result.first['total'] as int?) ?? 0;
      if (total > 0) return (obtained / total) * 100;
    }
    return 0.0;
  }

  Future<int> getTotalMockTestsCount(int paperId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM mock_tests WHERE paper_id = ?', [paperId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTopicsInProgressCount(int paperId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as c FROM topic_progress tp
      JOIN topics t ON tp.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE s.paper_id = ? AND tp.status = 'pending'
    ''', [paperId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns all study sessions with topic and subject names for history view
  Future<List<Map<String, dynamic>>> getAllSessionsWithDetails() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT ss.*, t.name as topic_name, s.name as subject_name, p.code as paper_code
      FROM study_sessions ss
      JOIN topics t ON ss.topic_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      JOIN papers p ON s.paper_id = p.id
      ORDER BY ss.date DESC
    ''');
  }

  /// Returns {strong, mid, weak} counts for topics in a subject
  Future<Map<String, int>> getTopicStrengthCounts(int subjectId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT tp.manual_strength FROM topics t
      LEFT JOIN topic_progress tp ON t.id = tp.topic_id
      WHERE t.subject_id = ?
    ''', [subjectId]);

    int strong = 0, mid = 0, weak = 0;
    for (final row in result) {
      final manual = row['manual_strength'] as String? ?? 'mid';
      if (manual == 'strong') strong++;
      else if (manual == 'weak') weak++;
      else mid++;
    }
    return {'strong': strong, 'mid': mid, 'weak': weak};
  }

  /// Returns per-subject strong/mid/weak counts for radar chart
  Future<List<Map<String, dynamic>>> getSubjectStrengthRadar(int paperId) async {
    final db = await instance.database;
    // Fully manual strength — no auto-computation
    final result = await db.rawQuery('''
      SELECT s.id, s.name as subject_name,
        COUNT(t.id) as total,
        SUM(CASE WHEN COALESCE(tp.manual_strength, 'mid') = 'strong' THEN 1 ELSE 0 END) as strong,
        SUM(CASE WHEN COALESCE(tp.manual_strength, 'mid') = 'mid' THEN 1 ELSE 0 END) as mid,
        SUM(CASE WHEN COALESCE(tp.manual_strength, 'mid') = 'weak' THEN 1 ELSE 0 END) as weak
      FROM subjects s
      LEFT JOIN topics t ON t.subject_id = s.id
      LEFT JOIN topic_progress tp ON t.id = tp.topic_id
      WHERE s.paper_id = ?
      GROUP BY s.id
      ORDER BY s.sort_order ASC
    ''', [paperId]);

    return result.map((row) => {
      'id': row['id'] as int,
      'name': row['subject_name'] as String,
      'total': (row['total'] as int?) ?? 0,
      'strong': (row['strong'] as int?) ?? 0,
      'mid': (row['mid'] as int?) ?? 0,
      'weak': (row['weak'] as int?) ?? 0,
    }).toList();
  }

  /// Returns topic-wise strength labels for all topics in a subject
  Future<List<Map<String, dynamic>>> getTopicStrengthDetails(int subjectId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT t.id, t.name, tp.status, tp.manual_strength
      FROM topics t
      LEFT JOIN topic_progress tp ON t.id = tp.topic_id
      WHERE t.subject_id = ?
      ORDER BY t.sort_order ASC
    ''', [subjectId]);

    final List<Map<String, dynamic>> details = [];
    for (final row in result) {
      final manual = row['manual_strength'] as String? ?? 'mid';
      details.add({
        'id': row['id'] as int,
        'name': row['name'] as String,
        'strength': manual,
        'status': (row['status'] as String?) ?? 'pending',
        'sessions': 0,
        'last_studied': null,
      });
    }
    return details;
  }

  String _todayDateStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _dateToStr(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
