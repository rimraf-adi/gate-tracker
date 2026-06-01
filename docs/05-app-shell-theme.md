# Step 05 — App Shell & Theme (Visual Design Integration)

## Goal
Create the app shell with floating bottom navigation, gradient background, custom theme, and routing. This doc integrates the neo-minimalist design system from Step 15.

## Files to create / modify

### 1. `pubspec.yaml` — Add font dependency
```yaml
dependencies:
  google_fonts: ^6.2.1
```

### 2. `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: GateTrackerApp()));
}
```

### 3. `lib/app.dart`
```dart
class GateTrackerApp extends StatelessWidget {
  const GateTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GATE Tracker',
      theme: AppTheme.light,
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 4. `lib/theme/app_theme.dart`
Implement the custom theme as defined in Step 15 — `AppTheme.light`, `AppColors`, `AppRadius`.

### 5. `lib/theme/app_background.dart`
`GradientBackground` widget wrapping the scaffold body in `LinearGradient(limeGreen → warmIvory → softLavender)`.

### 6. `lib/screens/app_shell.dart`
- Uses `IndexedStack` to hold 3 tab screens.
- Bottom nav uses `FloatingBottomNav` widget (from Step 15) instead of default `BottomNavigationBar`.

```dart
class AppShell extends StatefulWidget {
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    SubjectListScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _screens[_currentIndex],
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}
```

### 7. Routing
Keep routes for navigation:
- `/subjects/:subjectId` → topic detail
- `/mock-tests` → mock test screen (accessible from dashboard or as a modal)

Use `Navigator.pushNamed` within each tab. The bottom nav tabs themselves do not need a route change.

### 8. Paper selector
A `PopupMenuButton` or `SegmentedButton` at the top of relevant screens that switches `selectedPaperIdProvider`. Show custom papers with a small "CUSTOM" badge next to their name.

```dart
final selectedPaperIdProvider = StateProvider<int>((ref) => 1);
```

## Verification
- App launches with gradient background filling the full screen.
- Floating bottom nav is a black pill, detached from screen edges with 32px radius.
- Tapping tabs switches screens without rebuilding the nav.
- Selected tab is lavender (`AppColors.lavenderPurple`).
- No Material 3 blue/default colors visible anywhere.
