# Step 15 — Visual Design: Neo-Minimalist Premium UI

## Goal
Replace the basic Material 3 theme with a custom neo-minimalist glassmorphism-inspired design system. Every screen becomes visual-first: oversized typography, soft pastel gradients, floating rounded cards, and a premium dashboard aesthetic.

## Design System

### Color Palette

```dart
class AppColors {
  // Gradient background
  static const limeGreen   = Color(0xFFD9FF5A);
  static const warmIvory    = Color(0xFFF5F3ED);
  static const softLavender = Color(0xFFC6A8FF);

  // Accent
  static const lavenderPurple = Color(0xFFB69CFF);

  // Neutrals
  static const cardWhite    = Color(0xFFF8F8F8);
  static const darkSurface  = Color(0xFF111111);
  static const lightGray    = Color(0xFFE8E6E1);
}
```

Background: use a large `Container` with a `LinearGradient` from `limeGreen` → `warmIvory` → `softLavender` as the scaffold background.

### Typography
- Font: Inter, Plus Jakarta Sans, or SF Pro Display (use Google Fonts: `google_fonts` package)
- Large oversized text as design element:
  - Date header: 48px bold
  - Greeting: 24px medium
  - Subject name: 20px semibold
  - Topic status text: 16px medium
  - Small labels/counts: 13px regular

```yaml
dependencies:
  google_fonts: ^6.2.1
```

### Radius System
| Token | Value | Usage |
|---|---|---|
| `radiusSmall` | 16px | Small icons, chips |
| `radiusCard` | 24px | Cards, modals, dialogs |
| `radiusNav` | 32px | Bottom navigation bar |
| `radiusPill` | 999px | Buttons, tags, CTAs |

### Shadows
Subtle, no hard edges:
```dart
static final cardShadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.04),
  blurRadius: 12,
  offset: const Offset(0, 4),
);
```

## Reusable Widgets

### File: `lib/theme/app_theme.dart`

Replace the old Material 3 theme with the custom theme:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, height: 1.0),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      labelSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2),
    ),
  );
}

class AppRadius {
  static const small = 16.0;
  static const card = 24.0;
  static const nav = 32.0;
  static const pill = 999.0;
}
```

### File: `lib/theme/app_background.dart`

```dart
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.limeGreen,
            AppColors.warmIvory,
            AppColors.softLavender,
          ],
        ),
      ),
      child: child,
    );
  }
}
```

Wrap every screen's `Scaffold` body with `GradientBackground`.

### File: `lib/widgets/glass_card.dart`

Floating borderless card with extreme border radius:

```dart
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

### File: `lib/widgets/floating_bottom_nav.dart`

Bottom nav as a floating black pill detached from screen edges:

```dart
class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.nav),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.lavenderPurple,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Exams'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          ],
        ),
      ),
    );
  }
}
```

### File: `lib/widgets/date_header.dart`

The oversized date displayed as a visual hero element:

```dart
class DateHeader extends StatelessWidget {
  const DateHeader({super.key});

  String get _day => DateFormat('dd').format(DateTime.now());
  String get _month => DateFormat('MMMM').format(DateTime.now());
  String get _weekday => DateFormat('EEEE').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_day, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_month, style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.1)),
                Text(_weekday, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### File: `lib/widgets/progress_grid.dart`

Visual progress indicator — a tappable topic grid with checkmarks (replaces plain text list):

```dart
class ProgressGridItem {
  final String label;
  final bool completed;
  final ProgressStatus status;
  final VoidCallback onTap;
}

class ProgressGrid extends StatelessWidget {
  final List<ProgressGridItem> items;

  const ProgressGrid({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => _buildRow(context, item)).toList(),
    );
  }

  Widget _buildRow(BuildContext context, ProgressGridItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: item.completed ? AppColors.lavenderPurple.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.small),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.completed ? AppColors.lavenderPurple : AppColors.lightGray,
                  ),
                  child: item.completed
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : item.status == ProgressStatus.inProgress
                          ? const Icon(Icons.remove, size: 16, color: Colors.black54)
                          : null,
                ),
                const SizedBox(width: 14),
                Text(item.label, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### File: `lib/widgets/stats_ring.dart`

Circular progress ring for subject cards (replaces linear progress bars):

```dart
class StatsRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color color;

  const StatsRing({
    required this.progress,
    this.size = 48,
    this.color = AppColors.lavenderPurple,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
```

### File: `lib/widgets/action_button.dart`

Pill-shaped CTA buttons with lavender accent:

```dart
class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ActionButton({required this.label, required this.icon, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.lavenderPurple,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Screen-by-Screen Visual Layouts

### Dashboard Screen

```
┌──────────────────────────────┐
│  ░░░░░░░░░░░░░░░░░░░░░░░░░  │  ← Gradient background
│                              │
│  14                           │  ← Oversized date (displayLarge)
│  June    Saturday             │
│                              │
│  Hey Aditya 👋               │  ← Greeting
│                              │
│  Filter pills (horizontal)   │
│  ┌──────┐ ┌────────┐ ┌─────┐│
│  │ All  │ │In-Progress│Done││  ← Pill chips, lavender selected
│  └──────┘ └────────┘ └─────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ Operating Systems        ││  ← GlassCard
│  │ ⏰ 09:00 AM              ││
│  │                          ││
│  │   2 Days Left            ││  ← Lavender badge
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ Computer Networks        ││
│  │ ⏰ 02:00 PM              ││
│  │                          ││
│  │   5 Days Left            ││
│  └──────────────────────────┘│
│                              │
│   (space for floating nav)   │
│                              │
│       ╭─────────────╮        │  ← FloatingBottomNav
│       Home  Exams  Progress │
│       ╰─────────────╯        │
└──────────────────────────────┘
```

Key changes from old layout:
- Removed progress bar text stats — replaced with visual exam cards showing remaining days
- Added greeting and oversized date as hero element
- Added filter pills row (All / In Progress / Done)
- Exams shown as floating cards with time + countdown badge
- Progress is implied by exam card count, not explicit numbers

**Implementation:** `lib/screens/dashboard_screen.dart`

```dart
class DashboardScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            children: [
              const DateHeader(),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Hey Aditya 👋', style: Theme.of(context).textTheme.headlineMedium),
              ),
              const SizedBox(height: 20),
              const _FilterPills(),
              const SizedBox(height: 16),
              // ... exam cards
            ],
          ),
        ),
      ),
    );
  }
}
```

### Subject List Screen (Exams tab)

```
┌──────────────────────────────┐
│  ← Subjects                  │  ← White text on gradient
│                              │
│  Engineering Mathematics     │
│  ┌──────────────────────────┐│
│  │ 📐  Engg Math            ││  ← GlassCard
│  │                         ││
│  │ 12/20        ⭕ 60%     ││  ← StatsRing progress
│  └──────────────────────────┘│
│                              │
│  Digital Logic               │
│  ┌──────────────────────────┐│
│  │ 💻  Digital Logic        ││
│  │                         ││
│  │ 8/20         ⭕ 40%     ││
│  └──────────────────────────┘│
│                              │
│  ...                         │
│                              │
│       ╭─────────────╮        │
│       Home  Exams  Progress │
│       ╰─────────────╯        │
└──────────────────────────────┘
```

Key changes:
- Each subject is a `GlassCard` with emoji + name + `StatsRing` (circular progress)
- Topic count shown as fraction (12/20) instead of a linear bar
- Tapping navigates to topic detail

### Topic Detail Screen

```
┌──────────────────────────────┐
│  ← Engineering Mathematics   │
│                              │
│  Discrete Mathematics        │  ← Subject name as subtitle
│                              │
│  12/20 topics completed      │  ← Count text
│  ⭕ 60%                      │  ← Large StatsRing
│                              │
│  [➕ Log Study Session]      │  ← ActionButton (pill)
│                              │
│  ┌──────────────────────────┐│
│  │ ✓ Propositional Logic   ││  ← ProgressGrid items
│  │ ✓ Sets, relations       ││     Lavender bg = completed
│  │ ◌ Functions             ││     Grey circle = not started
│  │ ◌ Partial orders        ││
│  │ ◌ Monoids               ││
│  │ ◌ Groups                ││
│  └──────────────────────────┘│
│                              │
│  [Reset Progress]            │  ← Text button at bottom
└──────────────────────────────┘
```

Key changes:
- Progress ring instead of linear bar
- Topic list uses `ProgressGrid` with lavender filled circles for completed
- Tapping a row toggles status with haptic feedback
- Action button is pill-shaped lavender

### Mock Test Screen

```
┌──────────────────────────────┐
│  Mock Tests       [+ Add]   │
│                              │
│  CSE                          │  ← Paper chip
│                              │
│  ┌──────────────────────────┐│
│  │ GATE 2025 CSE            ││  ← GlassCard
│  │ March 18, 2025          ││
│  │                         ││
│  │  42 / 100               ││  ← Large fraction
│  │  ┌──────────────────┐   ││
│  │  │ ████████░░ 72%   │   ││  ← Lavender bar
│  │  └──────────────────┘   ││
│  │  Percentile: 94.2       ││  ← Small label
│  │  Rank: 1520             ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │ AIMT-3 CSE               ││
│  │ February 10, 2025       ││
│  │  38 / 100               ││
│  │  ████████░░ 65%         ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

Key changes:
- Score shown as large fraction `42 / 100` instead of inline text
- Percentage shown as a thin lavender bar below
- Date formatted with full month name
- Cleaner card layout with more whitespace

### Analytics Screen

```
┌──────────────────────────────┐
│  Progress                    │
│                              │
│  📚 Study Hours This Week   │
│  ┌──────────────────────────┐│
│  │                          ││
│  │ ▄▄▄▄▄▄  ▄▄▄             ││  ← Lavender bars
│  │ ██████  █████  ▄▄       ││     fl_chart with
│  │ ██████  █████  ████ ▄▄  ││     lavender accent
│  │ M  T  W  T  F  S  S    ││
│  └──────────────────────────┘│
│                              │
│  Syllabus Progress           │
│  ┌──────────────────────────┐│
│  │ CSE    ⭕ 78%            ││  ← StatsRing per paper
│  │ ECE    ⭕ 55%            ││
│  └──────────────────────────┘│
│                              │
│  Weak Spots                  │
│  ┌──────────────────────────┐│
│  │ ⚠ Graph algorithms      ││  ← GlassCard, small
│  │ ⚠ Cache memory          ││
│  │ ⚠ Normal forms          ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

Key changes:
- Study hours use lavender-colored bars (fl_chart `BarChart`)
- Syllabus progress uses `StatsRing` per paper instead of linear bars
- Weak spots listed as compact cards with warning icon
- Single scrollable page, all cards use `GlassCard` wrapper

## Applying the Design to Existing Screens

### What to change per file

| File | Change |
|---|---|
| `lib/main.dart` | Wrap `MaterialApp` — remove `themeMode` provider, keep theme as `AppTheme.light` |
| `lib/theme/app_theme.dart` | Replace with custom theme, add font setup, remove Material 3 references |
| `lib/screens/app_shell.dart` | Replace `BottomNavigationBar` with `FloatingBottomNav`, wrap body in `GradientBackground` |
| `lib/screens/dashboard_screen.dart` | Use `DateHeader`, greeting, filter pills, exam `GlassCard`s, remove progress bar text stats |
| `lib/screens/subject_list_screen.dart` | Use `GlassCard` + `StatsRing` per subject, remove emoji mapping doc (use actual subject emoji in cards) |
| `lib/screens/topic_detail_screen.dart` | Use `ProgressGrid` instead of plain list, `ActionButton` for log study, `StatsRing` for progress |
| `lib/screens/mock_test_screen.dart` | Wrap cards in `GlassCard`, show score as large fraction, add lavender percentage bar |
| `lib/screens/analytics_screen.dart` | Use `StatsRing` for per-paper progress, lavender bar chart, compact weak-spot cards |

## Verification
- All screens render on a real device without overflow or clipping.
- Gradient background spans full height on all screens.
- Floating bottom nav is detached from edges with `32px` border radius.
- `GlassCard` has consistent `24px` radius and subtle shadow.
- `StatsRing` animates on value change.
- `ProgressGrid` items toggle correctly on tap.
- Typography matches: 48px date, 24px greeting, 20px card titles.
