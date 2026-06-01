import 'package:flutter_test/flutter_test.dart';
import 'package:gate_tracker/models/paper.dart';
import 'package:gate_tracker/models/subject.dart';
import 'package:gate_tracker/models/topic.dart';
import 'package:gate_tracker/models/topic_progress.dart';
import 'package:gate_tracker/models/study_session.dart';
import 'package:gate_tracker/models/mock_test.dart';
import 'package:gate_tracker/models/mock_test_subject_breakdown.dart';

void main() {
  group('Models Serialization Round-trip Tests', () {
    test('Paper serialization', () {
      final paper = Paper(
        id: 1,
        code: 'CSE',
        fullName: 'Computer Science',
        isCustom: false,
        syllabusSource: 'Math, Logic',
        sortOrder: 0,
      );

      final map = paper.toMap();
      final fromMap = Paper.fromMap(map);

      expect(fromMap.id, paper.id);
      expect(fromMap.code, paper.code);
      expect(fromMap.fullName, paper.fullName);
      expect(fromMap.isCustom, paper.isCustom);
      expect(fromMap.syllabusSource, paper.syllabusSource);
      expect(fromMap.sortOrder, paper.sortOrder);
    });

    test('Subject serialization', () {
      final subject = Subject(
        id: 10,
        paperId: 2,
        name: 'Calculus',
        sortOrder: 3,
      );

      final map = subject.toMap();
      final fromMap = Subject.fromMap(map);

      expect(fromMap.id, subject.id);
      expect(fromMap.paperId, subject.paperId);
      expect(fromMap.name, subject.name);
      expect(fromMap.sortOrder, subject.sortOrder);
    });

    test('Topic serialization', () {
      final topic = Topic(
        id: 101,
        subjectId: 10,
        name: 'Limits and Continuity',
        sortOrder: 1,
      );

      final map = topic.toMap();
      final fromMap = Topic.fromMap(map);

      expect(fromMap.id, topic.id);
      expect(fromMap.subjectId, topic.subjectId);
      expect(fromMap.name, topic.name);
      expect(fromMap.sortOrder, topic.sortOrder);
    });

    test('TopicProgress serialization & status parsing', () {
      final progress = TopicProgress(
        id: 50,
        topicId: 101,
        status: ProgressStatus.completed,
        lastUpdated: DateTime(2026, 6, 1, 12, 0, 0),
      );

      final map = progress.toMap();
      final fromMap = TopicProgress.fromMap(map);

      expect(fromMap.id, progress.id);
      expect(fromMap.topicId, progress.topicId);
      expect(fromMap.status, progress.status);
      expect(fromMap.lastUpdated, progress.lastUpdated);

      // Test legacy 'inProgress' maps to 'pending'
      final legacyMap = {'id': 51, 'topic_id': 102, 'status': 'inProgress', 'last_updated': '2026-06-01T12:00:00.000'};
      final legacyParsed = TopicProgress.fromMap(legacyMap);
      expect(legacyParsed.status, ProgressStatus.pending);

      // Test legacy 'notStarted' maps to 'pending'
      final legacyMap2 = {'id': 52, 'topic_id': 103, 'status': 'notStarted', 'last_updated': null};
      final legacyParsed2 = TopicProgress.fromMap(legacyMap2);
      expect(legacyParsed2.status, ProgressStatus.pending);

      // Test pending status
      final pendingProgress = TopicProgress(
        id: 53,
        topicId: 104,
        status: ProgressStatus.pending,
      );
      final pendingMap = pendingProgress.toMap();
      final pendingFromMap = TopicProgress.fromMap(pendingMap);
      expect(pendingFromMap.status, ProgressStatus.pending);
    });

    test('StudySession serialization', () {
      final session = StudySession(
        id: 99,
        topicId: 101,
        date: DateTime(2026, 6, 1, 15, 30, 0),
        durationMinutes: 45,
      );

      final map = session.toMap();
      final fromMap = StudySession.fromMap(map);

      expect(fromMap.id, session.id);
      expect(fromMap.topicId, session.topicId);
      expect(fromMap.date, session.date);
      expect(fromMap.durationMinutes, session.durationMinutes);
    });

    test('MockTest serialization', () {
      final testResult = MockTest(
        id: 88,
        paperId: 1,
        testName: 'AIMT 1',
        date: DateTime(2026, 5, 20),
        totalMarks: 100,
        marksObtained: 55,
        percentile: 92.5,
        rank: 450,
      );

      final map = testResult.toMap();
      final fromMap = MockTest.fromMap(map);

      expect(fromMap.id, testResult.id);
      expect(fromMap.paperId, testResult.paperId);
      expect(fromMap.testName, testResult.testName);
      expect(fromMap.date, testResult.date);
      expect(fromMap.totalMarks, testResult.totalMarks);
      expect(fromMap.marksObtained, testResult.marksObtained);
      expect(fromMap.percentile, testResult.percentile);
      expect(fromMap.rank, testResult.rank);
    });

    test('MockTestSubjectBreakdown serialization', () {
      final breakdown = MockTestSubjectBreakdown(
        id: 77,
        mockTestId: 88,
        subjectId: 10,
        marksObtained: 15,
        totalMarks: 20,
      );

      final map = breakdown.toMap();
      final fromMap = MockTestSubjectBreakdown.fromMap(map);

      expect(fromMap.id, breakdown.id);
      expect(fromMap.mockTestId, breakdown.mockTestId);
      expect(fromMap.subjectId, breakdown.subjectId);
      expect(fromMap.marksObtained, breakdown.marksObtained);
      expect(fromMap.totalMarks, breakdown.totalMarks);
    });
  });
}
