# GATE Exam Tracker — Product Requirements Document

## Overview

A Flutter-based mobile app to help GATE aspirants track their preparation progress across subjects and topics. The app parses raw syllabus text files into structured data, lets users mark topics as done/in-progress/pending, records study time, tracks mock test scores, provides an analytics dashboard, supports custom exam syllabi with full editing capabilities, and features a neo-minimalist glassmorphism-inspired visual design with oversized typography, pastel gradients, and floating cards.

## References

- **Syllabus — CSE**: [`cse.txt`](../cse.txt) — 10 sections covering CS & IT (Engineering Math, Digital Logic, COA, Programming & DS, Algorithms, TOC, Compiler Design, OS, Databases, Computer Networks)
- **Syllabus — ECE**: [`ece.txt`](../ece.txt) — 8 sections covering ECE (Engineering Math, Networks/Signals/Systems, Electronic Devices, Analog Circuits, Digital Circuits, Control Systems, Communications, Electromagnetics)
- **Existing project**: `.` — base Flutter project (empty scaffold)

## Scope

### In Scope (v1.0)

| Feature | Description |
|---|---|
| Multi-paper syllabus parsing | Parse CSE & ECE syllabus text files into structured subject/topic tree |
| Subject & topic browsing | Browse all subjects, expand to see topics and sub-topics |
| Progress tracking | Mark topics as Not Started / In Progress / Completed with timestamps |
| Study session logging | Log study hours per topic with date |
| Mock test score tracker | Record test name, date, score, percentile, subject-wise breakdown |
| Analytics dashboard | Charts for aggregate progress, weak areas, study time trends |
| Custom exam/syllabus creator | Users can create custom exam papers, paste or type their own syllabus text, and parse it into subjects/topics |
| Syllabus editor | Edit subjects and topics of any existing paper (including CSE/ECE): rename, reorder, add, delete |
| Persistent local storage | All data stored locally via SQLite (sqflite) |
| Dark/Light theme | Toggle between material light and dark themes |

### Out of Scope (v1.0)

- User authentication / cloud sync
- Social/leaderboard features
- Push notifications
- PDF note-taking / annotation
- Video lecture linking
- Import syllabus from PDF or image
- Syllabus sharing between users

## User Personas

1. **GATE Aspirant** — wants to systematically track syllabus coverage, identify weak topics, and monitor mock test performance over time.
2. **Repeat Test-taker** — needs to compare progress across multiple attempts, focus on topics with low confidence.
3. **Custom Exam Taker** — preparing for a non-GATE exam (university, PSU, other entrance), needs to create a custom syllabus and track progress against it.
4. **Power User** — wants to fine-tune the pre-loaded CSE/ECE syllabi by renaming subjects, adding missing topics, or reorganizing sections.

## Functional Requirements

### FR1 — Syllabus Parsing
- Parse `cse.txt` and `ece.txt` into a structured model (Paper → Section → Topic → Sub-topic)
- Handle edge cases: line breaks mid-topic, indentation-based hierarchy, comma-separated sub-topics
- Store parsed data as seed data on first launch

### FR2 — Subject / Topic Browsing
- Show all sections as a card list with progress % per section
- Tap a section → drill into a list of topics
- Each topic shows its status badge (Not Started / In Progress / Completed)

### FR3 — Progress Tracking
- Tap topic to toggle status: Not Started → In Progress → Completed → Not Started
- Record the timestamp of last status change
- Overall progress bar at top of dashboard

### FR4 — Study Session Logging
- From a topic detail view, tap "+ Log Study" to record duration (15 min increments)
- Entries stored with date, topic ID, duration
- Daily / weekly / monthly study time charts

### FR5 — Mock Test Tracker
- Add a test entry: name, date, total marks, marks obtained, rank/percentile (optional)
- Optional subject-wise marks breakdown
- List of past tests sorted by date
- Performance trend chart

### FR6 — Analytics Dashboard
- Aggregate % of syllabus completed (per paper and overall)
- Weak topics (stuck on "In Progress" > 7 days)
- Study hours per day/week (bar chart)
- Mock score trend (line chart)

### FR7 — Custom Syllabus / Exam Creation
- "Add Exam" button on the paper selector or a dedicated screen
- Form: exam name, exam code (e.g. "GATE", "ESE", "PSU"), and a large text field to paste/type syllabus
- Syllabus text is parsed on-the-fly using the same parser algorithm from FR1
- User can review parsed subjects/topics before saving
- Custom papers are tagged with `is_custom = 1` and rendered with a distinct visual badge
- Custom papers can be deleted entirely (including all related progress data)

### FR8 — Syllabus Editing
- From any subject list screen, an "Edit" mode (toggle or long-press)
- Subject-level actions: rename, reorder (drag handle), delete with confirmation
- Topic-level actions: rename, add new topic, delete, reorder within a subject
- Changes persist immediately to SQLite
- Built-in undo snackbar for deletions (3-second window to undo)

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod |
| Local storage | sqflite (SQLite) |
| Charts | fl_chart |
| Design system | Custom neo-minimalist (no Material 3) — pastel gradient bg, extreme radius, oversized typography |
| Fonts | Google Fonts (Inter / Plus Jakarta Sans) |
| Minimum SDK | Flutter 3.12+ / Dart 3.12+ |

## Document Inventory

The following step-by-step build documents are executed sequentially by an AI to build the full application. All documents live in the `docs/` directory.

| # | Document | Purpose |
|---|---|---|---|
| 1 | [`docs/01-data-models.md`](./docs/01-data-models.md) | Define all Dart data models and the SQLite schema |
| 2 | [`docs/02-syllabus-loader.md`](./docs/02-syllabus-loader.md) | Parse `cse.txt` and `ece.txt` into structured data and seed the database |
| 3 | [`docs/03-database-layer.md`](./docs/03-database-layer.md) | Implement `DatabaseHelper` — CRUD for all entities |
| 4 | [`docs/04-provider-layer.md`](./docs/04-provider-layer.md) | State management with Riverpod providers |
| 5 | [`docs/05-app-shell-theme.md`](./docs/05-app-shell-theme.md) | App shell, routing, Material 3 theme (dark/light) |
| 6 | [`docs/06-dashboard-screen.md`](./docs/06-dashboard-screen.md) | Dashboard with progress summary and quick stats |
| 7 | [`docs/07-subject-list-screen.md`](./docs/07-subject-list-screen.md) | Subject listing with progress bars per section |
| 8 | [`docs/08-topic-detail-screen.md`](./docs/08-topic-detail-screen.md) | Topic drill-down with status toggle and study logger |
| 9 | [`docs/09-mock-test-screen.md`](./docs/09-mock-test-screen.md) | Mock test CRUD and test history list |
| 10 | [`docs/10-analytics-screen.md`](./docs/10-analytics-screen.md) | Charts for progress, study time, and mock trends |
| 11 | [`docs/11-syllabus-text-files.md`](./docs/11-syllabus-text-files.md) | Instructions to copy `cse.txt` / `ece.txt` into app assets |
| 12 | [`docs/12-testing-and-polish.md`](./docs/12-testing-and-polish.md) | Widget tests, integration tests, and final polish |
| 13 | [`docs/13-custom-syllabus-adder.md`](./docs/13-custom-syllabus-adder.md) | UI and logic to create custom exam papers with user-pasted syllabus text |
| 14 | [`docs/14-syllabus-editor.md`](./docs/14-syllabus-editor.md) | Edit subjects and topics of any paper (rename, add, delete, reorder) |
| 15 | [`docs/15-visual-design.md`](./docs/15-visual-design.md) | Neo-minimalist glassmorphism design system, reusable visual widgets, and screen-by-screen layout redraws |

## Success Metrics

- All syllabus sections from both CSE and ECE are parseable and browsable
- Custom exam can be created from pasted text and is immediately browsable
- Subjects and topics of CSE/ECE can be edited and changes persist
- Progress tracking persists across app restarts
- Mock test scores render in a chart without crashes
- App builds and runs on both iOS and Android without errors

## Timeline (AI-build estimate)

| Phase | Documents | Est. steps |
|---|---|---|
| Data layer | 01–04 | 4 steps |
| UI shell | 05 | 1 step |
| Feature screens | 06–10 | 5 steps |
| Assets & config | 11 | 1 step |
| Custom exam & editing | 13–14 | 2 steps |
| Visual design overhaul | 15 | 1 step |
| Testing & polish | 12 | 1 step |
| **Total** | **15 docs** | **15 steps** |
