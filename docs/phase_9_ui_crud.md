# Phase 9 Features: Theming, Hierarchy, and Advanced CRUD

This document outlines the technical design for the UI improvements, navigation changes, and data structure enhancements requested.

## 1. Theming, Colors, and Fonts 🎨

**Goal:** Elevate the app's aesthetics with modern typography and customizable, premium color palettes.

**Core Mechanics:**
- **Typography:** Integrate `google_fonts` (e.g., *Outfit* for headings, *Inter* for body text) to replace standard system fonts.
- **Colors:** Transition from hardcoded light colors to a dynamic theme system that supports multiple premium palettes (e.g., Deep Space Dark, Lavender Light, Mint Minimalist).
- **Overlays:** Fix bottom sheet overflows, ensure keyboard avoids overlapping text fields, and polish glassmorphism blur effects.

---

## 2. Navigation Updates 🧭

**Goal:** Clarify navigation intent based on the new app structure.

**Core Mechanics:**
- Rename the bottom navigation tab from **"Exams"** to **"Syllabus"**.
- Ensure all tooltips and empty states reflect this naming convention.

---

## 3. Log Study Hierarchy 📚

**Goal:** Make logging study sessions intuitive even when a user has hundreds of topics.

**Core Mechanics:**
- In the "Log Study" bottom sheet, replace the single long dropdown of topics with a cascading selection:
  1. **Select Subject** (e.g., Computer Networks)
  2. **Select Chapter** (e.g., Network Security)
  3. **Select Topic** (e.g., RSA Algorithm)
- This hierarchy will vastly improve scrolling and cognitive load.

---

## 4. Manual CRUD for Subjects & Chapters ✏️

**Goal:** Allow users to manually build and edit their syllabus structure without relying solely on the text parser.

**Core Mechanics:**
- **Subjects:** 
  - On the `SubjectListScreen` (Syllabus tab), add a Floating Action Button (FAB) or menu option to "Add Custom Subject".
  - Add long-press or swipe actions to edit or delete a subject.
- **Chapters & Topics:**
  - On the `TopicDetailScreen` (inside a subject), add the ability to "Add New Chapter" and "Add Topic" explicitly.
  - Currently, chapters are strings on the Topic model. Adding a chapter manually means adding an empty topic with that chapter name, or just allowing users to type a new chapter name when creating a topic. We will ensure the UI explicitly allows creating a Chapter block and organizing topics within it.
- **Deletions:**
  - Cascading deletes must be strictly enforced. Deleting a Subject will wipe all its Topics, Progress, Revisions, Notes, and Study Sessions.

---

## Implementation Strategy

1. **Pubspec & Theme:** Add `google_fonts` and implement the new `AppTheme` typography.
2. **Navbar & Overlays:** Quick rename of the navbar and fixing `MediaQuery.viewInsets` on all bottom sheets.
3. **Log Study Form:** Rewrite `_QuickLogStudyForm` to use cascading state variables for Subject -> Chapter -> Topic.
4. **CRUD UI:** Add dialogs for creating/editing Subjects and update the Chapter/Topic addition flows.
