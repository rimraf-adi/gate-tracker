# Phase 8 Features: Revision System, Scheduled Events, and Activity Heatmap

This document outlines the technical design and user experience for the three upcoming major features in GATE Tracker:

## 1. Spaced Repetition (Revision System) 🧠

**Goal:** Automatically schedule and track revision sessions for completed topics to ensure long-term retention.

**Core Mechanics:**
- When a topic's `ProgressStatus` changes to `completed`, an initial revision schedule is generated.
- Standard spaced repetition intervals: **1 day, 3 days, 7 days, 14 days, 30 days**.
- If a user misses a revision or marks it as "hard", the interval adjusts.

**Database Changes:**
- New table: `topic_revisions`
  - `id` (INTEGER PRIMARY KEY)
  - `topic_id` (INTEGER, FOREIGN KEY)
  - `scheduled_date` (TEXT)
  - `completed_date` (TEXT, NULLable)
  - `interval_days` (INTEGER)

**UI/UX Integrations:**
- **Calendar Marker:** A new colored dot (e.g., 🟠 Orange) on the calendar for days that have revisions due.
- **Due Today Widget:** On the Calendar Home Screen, a new section underneath "Selected Day Events" showing revisions due for the focused day.
- **Topic Detail:** A small icon on the topic row indicating if it's currently due for revision.

---

## 2. Scheduled Events (Future Study Planning) 📅

**Goal:** Allow users to plan their study schedule in advance by assigning topics to future dates.

**Core Mechanics:**
- Users can select a future date on the calendar and tap "Schedule Study".
- They pick a Subject and Topic they intend to study.
- Scheduled events act as goals for that day. When the day arrives, they can convert the scheduled event into a completed "Study Session" (logging the actual duration).

**Database Changes:**
- New table: `scheduled_events`
  - `id` (INTEGER PRIMARY KEY)
  - `topic_id` (INTEGER, FOREIGN KEY)
  - `scheduled_date` (TEXT)
  - `is_completed` (INTEGER, boolean)

**UI/UX Integrations:**
- **Calendar Marker:** A new colored dot (e.g., 🟡 Yellow) for future scheduled events.
- **Calendar Panel:** Tapping a future date shows the planned topics. Tapping a planned topic on the current date offers a "Start Studying / Log Session" quick action.

---

## 3. GitHub-Style Contribution Heatmap 🟩

**Goal:** Gamify studying and visually represent consistency over time.

**Core Mechanics:**
- Aggregate study hours per day over a longer period (e.g., last 3-6 months).
- Map the duration to a color intensity scale (e.g., 0 mins = gray, < 30 mins = light green, > 2 hours = dark green).

**Dependencies:**
- No new database tables needed. We will aggregate data from the existing `study_sessions` table.
- Package: We can use a package like `flutter_heatmap_calendar` or build a custom grid widget for maximum aesthetic control.

**UI/UX Integrations:**
- **Analytics Screen:** Add a new card at the top of the Analytics Screen.
- The heatmap will display a grid of squares, where columns represent weeks and rows represent days of the week.
- Tooltip on long-press/tap to show exact study hours for that specific date.

---

## Implementation Strategy

We will build these sequentially:
1. **Database Update (v4 Migration):** Create `topic_revisions` and `scheduled_events` tables.
2. **Providers & Logic:** Update Riverpod providers to calculate and fetch these new items.
3. **Heatmap UI:** Implement the visual heatmap on the Analytics screen.
4. **Calendar Enhancements:** Update the `CalendarScreen` to show the new markers and handle scheduling interactions.
