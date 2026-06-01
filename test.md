# Live Testing Guide — Flutter + VSCode

## Quick Start

### Run the app
```bash
flutter run
```
Picks the first available device. Press `r` in the terminal for hot reload, `R` for hot restart.

### Run on a specific device
```bash
flutter devices                    # list connected devices/emulators
flutter run -d <device-id>        # run on specific device
flutter run -d chrome             # web (if enabled)
flutter run -d macos              # macOS desktop (if enabled)
```

## VSCode Integration

### Keyboard shortcuts
| Action | Keys |
|---|---|
| Start debug | `F5` |
| Hot reload | `⌃F5` (Ctrl+F5) or save any file |
| Hot restart | `⇧⌘F5` (Shift+Cmd+F5) or `R` in terminal |
| Stop | `⇧F5` (Shift+F5) |
| Toggle debug panel | `⇧⌘D` (Shift+Cmd+D) |

### VSCode Run Configurations
Create `.vscode/launch.json` in the project root:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (iOS Simulator)",
      "type": "dart",
      "request": "launch",
      "flutterMode": "debug"
    },
    {
      "name": "Flutter (Android Emulator)",
      "type": "dart",
      "request": "launch",
      "deviceId": "emulator-5554",
      "flutterMode": "debug"
    },
    {
      "name": "Flutter (macOS)",
      "type": "dart",
      "request": "launch",
      "deviceId": "macos",
      "flutterMode": "debug"
    }
  ]
}
```

## Build & Analyze Commands

### Static analysis
```bash
flutter analyze                    # lint the whole project
dart fix --apply                   # auto-fix some lint issues
```

### Run tests
```bash
flutter test                       # run all tests
flutter test test/models/          # run a specific test directory
flutter test test/widget_test.dart # run a single test file
flutter test --reporter expanded   # verbose test output
```

### Build for release (final verification)
```bash
flutter build apk --debug          # Android APK
flutter build ios --debug --no-codesign  # iOS (macOS only)
flutter build web                  # Web
flutter build macos                # macOS desktop
```

## Hot Reload Workflow

### When to use Hot Reload (`r`)
After editing:
- UI layout / widget tree
- Theme colors and styles
- Strings and labels
- Asset references
- Most Dart code (functions, classes)

### When to use Hot Restart (`R`)
After editing:
- `main()` or top-level initializers
- `static final` / `const` fields
- `native` code or plugin registrations
- Model class constructors (notable exception: hot reload won't re-run constructors)
- Changes to `pubspec.yaml` or assets

### When to fully stop + rerun
- Changed `pubspec.yaml` (add dependency)
- Changed native code (Android Kotlin/Java, iOS Swift/ObjC)
- Database schema changes (delete or version-bump the app)
- Strange state corruption during hot reload

## Database Inspection

### Reset database (during development)
Uninstall the app from the device/emulator, then `flutter run`. This deletes the SQLite database and triggers the seed loader from scratch.

### Flutter DevTools
```bash
flutter pub global activate devtools  # one-time setup
flutter run --observatory-port=8080   # run with debug port
# Then open DevTools in browser: the URL is printed in the terminal
# Or use VSCode: View → Command Palette → "Dart: Open DevTools"
```

DevTools lets you:
- Inspect widget tree
- View database contents (via the "Logging" tab or direct print statements)
- Profile performance

## Common Debugging Patterns

### Print database state to console
Add this to any screen's `build` method temporarily:
```dart
// Debug: print all topics for subject 1
Future(() async {
  final db = await DatabaseHelper.instance.database;
  final rows = await db.rawQuery('SELECT * FROM topics WHERE subject_id = 1');
  debugPrint('TOPICS: $rows');
});
```

### Verify seed data on launch
```bash
flutter logs                       # stream device logs
# Then look for "TOPICS:" or other debugPrint output
```

### Widget rebuild tracking
Add `RepaintBoundary` or use the debug banner:
```dart
MaterialApp(debugShowCheckedModeBanner: true, ...)
```

## Checklist: Test Each Step

| Step | What to test | Command |
|---|---|---|
| 01 | `flutter analyze` — zero errors | `flutter analyze` |
| 02 | App launches, CSE/ECE syllabi load | `flutter run` → check no asset errors |
| 03 | Progress toggle persists after hot restart | toggle topic → `R` → verify state |
| 04 | Provider state rebuilds UI | change paper → verify subject list updates |
| 05 | Bottom nav switches tabs | tap Home/Exams/Progress |
| 06 | Dashboard shows date + exam cards | verify date header renders |
| 07 | Subject cards have progress rings | verify StatsRing % matches data |
| 08 | Topic grid toggles on tap | tap topic → verify circle fills |
| 09 | Mock test add/delete works | add test → appears in list → delete → undo |
| 10 | Charts render without errors | verify bar chart + line chart visible |
| 13 | Custom exam creation flow | paste syllabus → parse → save → verify in selector |
| 14 | Edit mode on subjects/topics | rename, add, delete, reorder → verify persistence |
| 15 | Visual design matches spec | gradient bg, floating nav, glass cards, oversized date |

## Pro Tips

- **Keep a terminal open** with `flutter run` and use VSCode's integrated terminal. Edit code, save (⌘S), and see changes in under a second.
- **Use VSCode multi-cursor** (⌥⌘↑/↓) for bulk renaming model fields.
- **Test on a real device** — emulators are slower and gestures feel different.
- **For database debugging** during development, consider adding a temporary "Delete All Data" button in a debug menu.
- **`flutter clean`** when things get weird — it removes build cache and `.dart_tool/`. Then `flutter pub get && flutter run`.
