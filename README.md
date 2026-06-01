# ⚡ GATE Tracker ⚡

A premium, feature-rich study planner and progress tracker for GATE (Graduate Aptitude Test in Engineering) aspirants. Designed with a gorgeous, high-contrast **Dark Neon Aesthetic** and powered by offline-first SQLite database synchronization.

---

## 🎨 Premium Dark Neon Aesthetic
*   **Deep Cyberpunk Palette**: Dark base layout (`0xFF0A0E17`) with vibrant accent colors representing different status levels (Neon Purple, Neon Lime, Neon Orange).
*   **Glassmorphic Cards**: Beautiful semi-transparent container cards with custom gradient borders.
*   **Intuitive Floating Navigation**: Custom active indicator bar that dynamically adapts to view changes.

---

## 🚀 Key Features

### 📅 Interactive Calendar Hub (Home Screen)
*   **Dynamic Scheduling**: Drag/click to schedule study sessions, revision reminders, and mock test events.
*   **Study Heatmap**: Github-style daily contribution grid showing revision and learning intensity.
*   **Status Filters**: View Pending and Completed tasks at a glance (simplifying progress management).

### 📚 Intelligent Syllabus Progress (Syllabus Screen)
*   **Hierarchical Navigation**: Dynamically structured Subjects → Chapters → Topics layout for structured browsing.
*   **Manual CRUD Operations**: Flexibly create, edit, or delete custom Subjects, Chapters, and Topics alongside preloaded syllabi (CSE, ECE).
*   **Rich Topic Annotations**: Add text comments and capture/attach images directly to specific topics for persistent revision notes.

### 📊 Advanced Performance Visuals (Analytics Screen)
*   **Subject Mastery Radar Chart**: Fully responsive radar visualization showing your completion rates and strength across subjects.
*   **Mock Test Breakdown**: Track overall scores, subject-wise percentage marks, and time management over multiple exams.
*   **Weekly Study Statistics**: Bar charts and rings depicting study sessions logged vs goal hours.

---

## 🛠️ Project Structure
```text
lib/
├── models/           # Data definitions (Subject, Chapter, Topic, MockTest, Notes, Events)
├── providers/        # State Management (StateNotifier + Riverpod)
├── screens/          # Screen Widgets (Calendar, Syllabus, Analytics, TopicDetails, etc.)
├── services/         # Business Logic (SQLite Database, SharedPreferences, Syllabus Loader)
├── theme/            # Global custom Dark Neon design tokens
└── widgets/          # Reusable customized UI components (Heatmap, Ring stats, Filter pills)
```

---

## 📦 Running Locally

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.12.0+)
*   Android SDK / Xcode for iOS simulation

### Step-by-Step Execution
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/rimraf-adi/gate-tracker.git
    cd gate_tracker
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run Tests**:
    ```bash
    flutter test
    ```

4.  **Run Application**:
    ```bash
    flutter run
    ```
