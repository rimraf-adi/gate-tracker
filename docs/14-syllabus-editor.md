# Step 14 — Syllabus Editor

## Goal
Allow users to edit subjects and topics of any existing paper — built-in (CSE, ECE) or custom. Supported actions: rename, add, delete, reorder.

## Overview
The subject list screen and topic detail screen gain an "Edit" mode. When enabled, each item gets edit/delete controls and a drag handle for reordering.

## Implementation

### 1. Edit mode toggle
Add an `isEditing` boolean to the subject and topic screen states. Toggle with an AppBar action button (pencil icon).

When `isEditing == true`:
- Each card/row shows a drag handle on the left
- Each card/row shows a delete (trash) icon button on the right
- A FAB appears: "➕ Add Subject" (on subject list) or "➕ Add Topic" (on topic detail)
- Tapping a row opens an inline rename text field instead of navigating/toggling progress

### 2. File: `lib/screens/subject_list_screen.dart` — Extend with edit mode

```dart
class SubjectListScreen extends ConsumerStatefulWidget { ... }
class _SubjectListScreenState extends ConsumerState<SubjectListScreen> {
  bool _isEditing = false;

  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: subjectsListView(),
      floatingActionButton: _isEditing
          ? FloatingActionButton.small(
              onPressed: _showAddSubjectDialog,
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
```

### 3. Rename subject/topic
Tapping an item in edit mode:

```dart
Future<void> _showRenameDialog(String currentName, {required bool isSubject, required int id}) async {
  final controller = TextEditingController(text: currentName);
  final newName = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Rename'),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text('Save'),
        ),
      ],
    ),
  );
  if (newName != null && newName.isNotEmpty) {
    if (isSubject) {
      await DatabaseHelper.instance.updateSubject(subject.copyWith(name: newName));
    } else {
      await DatabaseHelper.instance.updateTopic(topic.copyWith(name: newName));
    }
    ref.invalidate(subjectsByPaperProvider(paperId));
  }
}
```

### 4. Add subject/topic

**Add Subject** — Dialog with name field. On save:
```dart
final subjects = await DatabaseHelper.instance.getSubjectsByPaper(paperId);
final newSubject = Subject(
  paperId: paperId,
  name: name,
  sortOrder: subjects.length,
);
await DatabaseHelper.instance.insertSubject(newSubject);
ref.invalidate(subjectsByPaperProvider(paperId));
```

**Add Topic** — Dialog with name field and a dropdown to pick which subject (if triggered from subject list level). If triggered from within a topic detail screen, the subject is known.

### 5. Delete subject/topic

Show a confirmation dialog, then:
```dart
await DatabaseHelper.instance.deleteSubject(subjectId);
// This should cascade-delete all associated topics, progress, and study sessions
```

Show a snackbar with "Undo" action for 3 seconds:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Deleted "${item.name}"'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () {
        // Re-insert the item (store deleted data in memory)
        DatabaseHelper.instance.insertSubject(deletedSubject);
        ref.invalidate(subjectsByPaperProvider(paperId));
      },
    ),
    duration: Duration(seconds: 3),
  ),
);
```

### 6. Reorder (drag and drop)

Use `ReorderableListView`:

```dart
ReorderableListView(
  children: subjects.map((s) => SubjectCard(
    key: ValueKey(s.id),
    subject: s,
    isEditing: _isEditing,
    // ...
  )).toList(),
  onReorder: (oldIndex, newIndex) async {
    final updated = List<Subject>.from(subjects);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    // Update sort_order for all items
    for (var i = 0; i < updated.length; i++) {
      await DatabaseHelper.instance.updateSubject(updated[i].copyWith(sortOrder: i));
    }
    ref.invalidate(subjectsByPaperProvider(paperId));
  },
);
```

### 7. Disable editing for built-in papers (or allow it)
Decision: **editing is allowed for all papers, including built-in ones**. This lets users customize CSE/ECE syllabi to match their study plan (e.g. merging two subjects, adding missing topics).

However, there is a "Reset to Default" button in the paper settings menu that re-runs the seed loader for built-in papers, deleting all user edits and restoring the original syllabus.

### 8. Reset to default — `lib/screens/paper_settings_sheet.dart`

```dart
Future<void> _resetToDefault(int paperId) async {
  final confirmed = await showConfirmDialog(context, 'Reset syllabus to default? This will delete all your edits.');
  if (confirmed == true) {
    await DatabaseHelper.instance.deletePaper(paperId); // cascade delete
    await SyllabusLoader.instance.loadSingle(paperCode); // re-parse from asset
    ref.invalidate(allPapersProvider);
  }
}
```

This only appears for non-custom papers (CSE, ECE).

## Verification
- Enter edit mode on subject list for CSE.
- Rename "Engineering Mathematics" to "Maths".
- Add a new subject called "Aptitude".
- Delete a subject → Undo works.
- Reorder subjects via drag.
- Verify changes persist after app restart.
- Reset CSE to default → original syllabus is restored.
