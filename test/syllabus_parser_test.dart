import 'package:flutter_test/flutter_test.dart';
import 'package:gate_tracker/services/syllabus_parser.dart';

void main() {
  group('SyllabusParser Tests', () {
    final parser = SyllabusParser();

    test('Parse basic syllabus text successfully', () {
      const syllabusText = '''
SYLLABUS : SAMPLE EXAM
Section 1 : Engineering Mathematics
Discrete Mathematics, Linear Algebra, Calculus
Section 2 : Computer Networks
Concept of layering, Ethernet routing, TCP/UDP sockets
''';

      final result = parser.parseSyllabusText(syllabusText, paperId: 99);

      // Verify subjects
      expect(result.subjects.length, 2);
      expect(result.subjects[0].name, 'Engineering Mathematics');
      expect(result.subjects[0].paperId, 99);
      expect(result.subjects[0].sortOrder, 0);

      expect(result.subjects[1].name, 'Computer Networks');
      expect(result.subjects[1].paperId, 99);
      expect(result.subjects[1].sortOrder, 1);

      // Verify topics
      expect(result.topics.length, 2);
      expect(result.topics[0].length, 3);
      expect(result.topics[0][0].name, 'Discrete Mathematics');
      expect(result.topics[0][1].name, 'Linear Algebra');
      expect(result.topics[0][2].name, 'Calculus');

      expect(result.topics[1].length, 3);
      expect(result.topics[1][0].name, 'Concept of layering');
      expect(result.topics[1][1].name, 'Ethernet routing');
      expect(result.topics[1][2].name, 'TCP/UDP sockets');
    });

    test('Parse edge cases like empty lines and leading/trailing spaces', () {
      const rawText = '''

Section 1: General Aptitude

  Verbal Ability ,   Numerical Ability  

Section 2: Engineering Mathematics
Probability  ,  Statistics

''';

      final result = parser.parseCustomSyllabus(rawText);

      expect(result.subjects.length, 2);
      expect(result.subjects[0].name, 'General Aptitude');
      expect(result.subjects[1].name, 'Engineering Mathematics');

      expect(result.topics[0].length, 2);
      expect(result.topics[0][0].name, 'Verbal Ability');
      expect(result.topics[0][1].name, 'Numerical Ability');

      expect(result.topics[1].length, 2);
      expect(result.topics[1][0].name, 'Probability');
      expect(result.topics[1][1].name, 'Statistics');
    });

    test('Parse syllabus text with chapters (colon formatted)', () {
      const syllabusText = '''
Section 1 : Engineering Mathematics
Discrete Mathematics: Propositional logic, Sets, relations
Linear Algebra: Matrices, eigenvalues
Section 2 : Computer Networks
Concept of layering: OSI model, TCP/IP stack
''';

      final result = parser.parseSyllabusText(syllabusText, paperId: 101);

      // Verify subjects
      expect(result.subjects.length, 2);

      // Verify chapters and topics
      expect(result.topics[0][0].chapter, 'Discrete Mathematics');
      expect(result.topics[0][0].name, 'Propositional logic');
      expect(result.topics[0][1].chapter, 'Discrete Mathematics');
      expect(result.topics[0][1].name, 'Sets');
      expect(result.topics[0][2].chapter, 'Discrete Mathematics');
      expect(result.topics[0][2].name, 'relations');
      
      expect(result.topics[0][3].chapter, 'Linear Algebra');
      expect(result.topics[0][3].name, 'Matrices');

      expect(result.topics[1][0].chapter, 'Concept of layering');
      expect(result.topics[1][0].name, 'OSI model');
    });
  });
}
