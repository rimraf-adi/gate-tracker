# Step 02 — Syllabus Loader

## Goal
Parse the raw syllabus text files (`cse.txt`, `ece.txt`) into structured `Paper` → `Subject` → `Topic` records, and insert them as seed data on app first launch.

## Parsing Rules

### Format of syllabi
- **Section header**: lines matching `Section \d+ : (.+)` or `Section\d+: (.+)`
- **Topics**: comma-separated items within section lines
- **Sub-topics**: items after a colon inside a topic (e.g. "Discrete Mathematics: Propositional and first order logic" — store as Topic name "Discrete Mathematics" with note about sub-topics)

### Algorithm per file
1. Read the raw text.
2. Identify the paper code from the first line (`COMPUTER SCIENCE AND INFORMATION TECHNOLOGY` → CSE, `ELECTRONICS & COMM. ENGINEERING` → ECE).
3. Split by newlines.
4. For each line:
   - If line matches section pattern → extract section name, create a `Subject`.
   - Otherwise → treat content as topics: split by `,`, trim each, create `Topic` records under current subject.
5. After parsing, insert paper → subjects → topics into SQLite in a transaction.

### First-launch guard
```dart
Future<bool> _isSeedDataLoaded() async {
  final count = await db.rawQuery('SELECT COUNT(*) as c FROM papers');
  return (count.first['c'] as int) > 0;
}
```

Only run the loader when `papers` table is empty.

## Files to create

| File | Purpose |
|---|---|
| `lib/services/syllabus_loader.dart` | Parse logic |
| `lib/services/syllabus_parser.dart` | Low-level line-by-line parser |
| `assets/cse.txt` | Copy from project root |
| `assets/ece.txt` | Copy from project root |

Register asset paths in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/cse.txt
    - assets/ece.txt
```

## Error Handling
- If a file can't be read, log error and show a snackbar on first screen.
- If the section regex doesn't match, treat entire line as topic content for the current section.
- Skip empty lines.

## Verification
- Run the parser against both files and print the resulting tree.
- Verify all sections from `cse.txt` (10) and `ece.txt` (8) are captured.
- Verify database has correct row counts after seeding.
