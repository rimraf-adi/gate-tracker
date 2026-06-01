import 'dart:convert';
import '../models/subject.dart';
import '../models/topic.dart';

class ParseResult {
  final List<Subject> subjects;
  final List<List<Topic>> topics;

  ParseResult({required this.subjects, required this.topics});
}

class SyllabusParser {
  ParseResult parseSyllabusText(String text, {int paperId = 0}) {
    final subjects = <Subject>[];
    final topics = <List<Topic>>[];
    int subjectSort = 0;
    String currentChapter = '';

    final lines = const LineSplitter().convert(text);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check if it's a first line metadata like "SYLLABUS : ..."
      if (trimmed.toUpperCase().startsWith('SYLLABUS')) {
        continue;
      }

      // Match "Section X: Subject Name" or "Section X : Subject Name"
      final sectionMatch = RegExp(
        r'^Section\s*\d+\s*:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed);

      if (sectionMatch != null) {
        final subjectName = sectionMatch.group(1)!.trim();
        subjects.add(Subject(
          paperId: paperId,
          name: subjectName,
          sortOrder: subjectSort++,
        ));
        topics.add([]);
        currentChapter = subjectName;
      } else {
        // If we haven't seen a section yet, ignore or add under a default section
        if (subjects.isEmpty) {
          subjects.add(Subject(
            paperId: paperId,
            name: 'General',
            sortOrder: subjectSort++,
          ));
          topics.add([]);
          currentChapter = 'General';
        }

        // Check if the line contains a colon representing Chapter: Topic1, Topic2, ...
        final colonIdx = trimmed.indexOf(':');
        String parsingText = trimmed;
        String lineChapter = currentChapter;

        if (colonIdx > 0 && colonIdx < trimmed.length - 1) {
          final potentialChapter = trimmed.substring(0, colonIdx).trim();
          if (potentialChapter.length < 50 && !potentialChapter.contains(',')) {
            lineChapter = potentialChapter;
            parsingText = trimmed.substring(colonIdx + 1).trim();
            currentChapter = lineChapter;
          }
        }

        // Split line by commas
        final parts = parsingText.split(',');
        for (final part in parts) {
          final topicName = part.trim();
          if (topicName.isNotEmpty) {
            topics.last.add(Topic(
              subjectId: 0, // Assigned later
              name: topicName,
              chapter: lineChapter,
              sortOrder: topics.last.length,
            ));
          }
        }
      }
    }

    return ParseResult(subjects: subjects, topics: topics);
  }

  ParseResult parseCustomSyllabus(String text) {
    // Custom syllabus parsing uses the same parser but paperId is not yet known
    return parseSyllabusText(text);
  }
}
