# Step 11 — Syllabus Text Files in Assets

## Goal
Ensure `cse.txt` and `ece.txt` are properly copied into the Flutter assets directory and registered in `pubspec.yaml`.

## Actions

### 1. Copy files
```bash
cp /Users/adityakinjawadekar/Documents/100xcode/gate-tracker/cse.txt \
   /Users/adityakinjawadekar/Documents/100xcode/gate-tracker/gate_tracker/assets/cse.txt

cp /Users/adityakinjawadekar/Documents/100xcode/gate-tracker/ece.txt \
   /Users/adityakinjawadekar/Documents/100xcode/gate-tracker/gate_tracker/assets/ece.txt
```

### 2. Register in `pubspec.yaml`
```yaml
flutter:
  assets:
    - assets/cse.txt
    - assets/ece.txt
```

### 3. Load in syllabus loader
In `syllabus_loader.dart`, load assets using:
```dart
Future<String> _loadAsset(String path) async {
  return await rootBundle.loadString(path);
}
```

## Verification
- `flutter run` with the app → no asset loading errors in console.
- `loadString('assets/cse.txt')` returns non-empty string.
