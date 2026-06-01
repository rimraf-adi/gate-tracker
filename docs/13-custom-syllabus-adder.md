# Step 13 — Custom Syllabus / Exam Adder

## Goal
Allow users to create custom exam papers by pasting or typing their own syllabus text, then parsing it into subjects and topics using the same algorithm from Step 02.

## Overview
Any exam other than the built-in CSE/ECE can be added: university semester exams, PSU recruitment tests, ESE, IES, or any custom study plan.

## Flow
1. User taps "Add Exam" from the paper selector or a dedicated FAB on the dashboard.
2. A form opens with fields: **Exam Name**, **Exam Code** (auto-generated if blank), **Syllabus Text** (large multi-line text field).
3. User pastes/types syllabus text following a simple format (see below).
4. "Parse & Preview" button runs the parser and shows a preview tree of subjects/topics.
5. User can edit parsed entries before confirming.
6. "Save Exam" inserts the paper, subjects, and topics into SQLite.

## Syllabus Text Format

The parser accepts the same format as the built-in syllabi:

```
Section 1 : Subject Name
topic A, topic B, topic C,
topic D,
Section 2 : Another Subject
topic X, topic Y
```

Rules:
- Lines matching `Section \d+\s*:\s*(.+)` start a new subject
- Everything after the colon in a section line becomes the subject name
- Non-section lines are split by commas, each trimmed item becomes a topic
- Empty lines are skipped

## Implementation

### File: `lib/screens/custom_exam_form_screen.dart`

```dart
class CustomExamFormScreen extends ConsumerStatefulWidget { ... }

class _CustomExamFormScreenState extends ConsumerState<CustomExamFormScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _syllabusController = TextEditingController();
  List<Subject> _parsedSubjects = [];
  List<List<Topic>> _parsedTopics = [];
  bool _showPreview = false;

  void _parseAndPreview() {
    final parser = SyllabusParser();
    final result = parser.parseCustomSyllabus(_syllabusController.text);
    setState(() {
      _parsedSubjects = result.subjects;
      _parsedTopics = result.topics;
      _showPreview = true;
    });
  }

  Future<void> _save() async {
    // Insert paper + subjects + topics in a transaction
    final db = DatabaseHelper.instance;
    final paper = Paper(
      code: _codeController.text.isNotEmpty
          ? _codeController.text.trim()
          : 'CUSTOM-${DateTime.now().millisecondsSinceEpoch}',
      fullName: _nameController.text.trim(),
      isCustom: true,
      syllabusSource: _syllabusController.text,
    );
    final paperId = await db.insertPaper(paper);
    for (var i = 0; i < _parsedSubjects.length; i++) {
      final subject = _parsedSubjects[i].copyWith(paperId: paperId, sortOrder: i);
      final subjectId = await db.insertSubject(subject);
      for (var j = 0; j < _parsedTopics[i].length; j++) {
        final topic = _parsedTopics[i][j].copyWith(subjectId: subjectId, sortOrder: j);
        await db.insertTopic(topic);
      }
    }
    if (mounted) Navigator.pop(context, true);
  }
}
```

### Parser extension — `lib/services/syllabus_parser.dart`

Add a new method:

```dart
class ParseResult {
  final List<Subject> subjects;
  final List<List<Topic>> topics;
}

ParseResult parseCustomSyllabus(String text) {
  final subjects = <Subject>[];
  final topics = <List<Topic>>[];
  int subjectSort = 0;

  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final sectionMatch = RegExp(r'Section\s+\d+\s*:\s*(.+)', caseSensitive: false).firstMatch(trimmed);
    if (sectionMatch != null) {
      subjects.add(Subject(name: sectionMatch.group(1)!.trim(), sortOrder: subjectSort++));
      topics.add([]);
    } else if (subjects.isNotEmpty) {
      final items = trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
      for (final item in items) {
        topics.last.add(Topic(name: item, sortOrder: topics.last.length));
      }
    }
  }
  return ParseResult(subjects: subjects, topics: topics);
}
```

### UI: Preview list
After parsing, show a `ListView` where each subject is an expandable tile. The tile header shows the subject name (editable inline via `TextFormField`). Expanding it shows its topics (also editable, with an "Add Topic" button at the bottom).

### Paper selector integration
In `lib/widgets/paper_selector.dart` (or wherever the paper picker lives):
- Add `SegmentedButton` for built-in papers + a final "➕ Add Exam" option
- OR use a `DropdownButton` with a "➕ Add Custom Exam" action at the bottom

When "Add Custom Exam" is selected → navigate to `CustomExamFormScreen`.

On return with result `true` → invalidate `allPapersProvider` so the new exam appears.

### Custom paper badge
In the paper selector and anywhere papers are displayed, custom papers show a small `CUSTOM` chip/badge and a different icon (e.g. `Icons.edit_note`).

## Verification
- Create a custom exam with 3 subjects and ~10 topics total.
- The new paper appears in the paper selector with a custom badge.
- Browsing its subjects and topics works identically to built-in papers.
- Progress tracking works on custom exam topics.
- Re-launch the app → custom exam persists.
