import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'database_helper.dart';
import 'syllabus_parser.dart';
import '../models/paper.dart';

class SyllabusLoader {
  static final SyllabusLoader instance = SyllabusLoader._init();
  SyllabusLoader._init();

  Future<void> loadAllIfNeeded() async {
    final db = DatabaseHelper.instance;
    final papers = await db.getAllPapers();
    if (papers.isEmpty) {
      await loadSingle('CSE');
      await loadSingle('ECE');
    }
  }

  Future<void> loadSingle(String paperCode) async {
    final db = DatabaseHelper.instance;
    
    // Delete existing paper if it exists
    final existing = await db.getPaperByCode(paperCode);
    if (existing != null) {
      await db.deletePaper(existing.id!);
    }

    String fullName = '';
    String assetPath = '';
    int sortOrder = 0;

    if (paperCode == 'CSE') {
      fullName = 'Computer Science & Information Technology';
      assetPath = 'assets/cse.txt';
      sortOrder = 0;
    } else if (paperCode == 'ECE') {
      fullName = 'Electronics & Comm. Engineering';
      assetPath = 'assets/ece.txt';
      sortOrder = 1;
    } else {
      throw Exception('Unknown built-in paper code: $paperCode');
    }

    try {
      final text = await rootBundle.loadString(assetPath);
      final parser = SyllabusParser();
      
      final paper = Paper(
        code: paperCode,
        fullName: fullName,
        isCustom: false,
        sortOrder: sortOrder,
      );
      final paperId = await db.insertPaper(paper);

      final result = parser.parseSyllabusText(text, paperId: paperId);

      for (var i = 0; i < result.subjects.length; i++) {
        final subject = result.subjects[i].copyWith(paperId: paperId, sortOrder: i);
        final subjectId = await db.insertSubject(subject);

        for (var j = 0; j < result.topics[i].length; j++) {
          final topic = result.topics[i][j].copyWith(subjectId: subjectId, sortOrder: j);
          await db.insertTopic(topic);
        }
      }
    } catch (e) {
      // For fallback or debugging
      debugPrint('Error loading syllabus asset for $paperCode: $e');
      rethrow;
    }
  }
}
