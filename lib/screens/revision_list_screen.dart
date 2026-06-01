import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../services/database_helper.dart';
import '../models/study_session.dart';

class RevisionListScreen extends ConsumerWidget {
  const RevisionListScreen({super.key});

  void _logRevision(BuildContext context, WidgetRef ref) async {
    final paperId = ref.read(selectedPaperIdProvider);
    final db = DatabaseHelper.instance;
    final subjects = await db.getSubjectsByPaper(paperId);
    if (subjects.isEmpty || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
      builder: (ctx) => _LogRevisionForm(subjects: subjects, onComplete: () {
        ref.invalidate(revisionHistoryProvider(paperId));
        ref.invalidate(activityHeatmapProvider);
        ref.invalidate(studyHoursPerDayProvider(7));
        ref.invalidate(totalStudyHoursProvider);
        ref.invalidate(totalStudySessionsCountProvider);
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final historyAsync = ref.watch(revisionHistoryProvider(paperId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.replay_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                  SizedBox(width: 10),
                  Text('Revisions',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.playlist_add_rounded, size: 24, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => _logRevision(context, ref),
                    tooltip: 'Log Revision',
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, size: 22, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => ref.invalidate(revisionHistoryProvider(ref.read(selectedPaperIdProvider))),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Tap + to log a revision session',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
            ),
            SizedBox(height: 16),
            Expanded(
              child: historyAsync.when(
                data: (revisions) {
                  if (revisions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.replay_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                          SizedBox(height: 16),
                          Text('No revisions yet',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text('Complete a topic or tap + to start',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  // Group by subject
                  final Map<String, List<Map<String, dynamic>>> grouped = {};
                  for (final r in revisions) {
                    final subject = r['subject_name'] as String? ?? 'Other';
                    grouped.putIfAbsent(subject, () => []).add(r);
                  }
                  final sortedSubjects = grouped.keys.toList()..sort();

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sortedSubjects.length,
                    itemBuilder: (context, i) {
                      final subject = sortedSubjects[i];
                      final items = grouped[subject]!;
                      final uniqueTopics = items.map((r) => r['topic_name'] as String).toSet().length;
                      final totalRevisions = items.length;
                      final emoji = _emojiFor(subject);

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          childrenPadding: EdgeInsets.only(bottom: 8),
                          shape: Border(),
                          leading: Text(emoji, style: TextStyle(fontSize: 24)),
                          title: Text(subject,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text('$uniqueTopics topics · $totalRevisions revisions',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                          children: items.asMap().entries.map((entry) {
                            final i = entry.key;
                            final r = entry.value;
                            final topicName = r['topic_name'] as String? ?? '';
                            final chapter = r['chapter_name'] as String? ?? '';
                            final attempts = r['attempts'] as int? ?? 0;
                            return Container(
                              decoration: BoxDecoration(
                                border: i > 0 ? Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06))) : null,
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text('$attempts',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(topicName,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                        if (chapter.isNotEmpty)
                                          Text(chapter,
                                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.replay_rounded, size: 12, color: Theme.of(context).colorScheme.primary),
                                        SizedBox(width: 4),
                                        Text('$attempts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emojiFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('math')) return '📐';
    if (n.contains('digital')) return '💻';
    if (n.contains('computer org') || n.contains('architecture')) return '🖥️';
    if (n.contains('program') || n.contains('data structure')) return '👨‍💻';
    if (n.contains('algo')) return '⚙️';
    if (n.contains('theory') || n.contains('toc') || n.contains('computation')) return '🔬';
    if (n.contains('compiler')) return '🔧';
    if (n.contains('operating') || n.contains('os')) return '⚡';
    if (n.contains('database') || n.contains('db')) return '🗄️';
    if (n.contains('network')) return '🌐';
    if (n.contains('signal') || n.contains('system')) return '📡';
    if (n.contains('device') || n.contains('electron')) return '🔌';
    if (n.contains('analog') || n.contains('circuit')) return '⚡';
    if (n.contains('control')) return '🎛️';
    if (n.contains('comm')) return '📶';
    if (n.contains('electromag')) return '🧲';
    return '📂';
  }
}

// ─── Log Revision Form (bottom sheet) ───

class _LogRevisionForm extends ConsumerStatefulWidget {
  final List<dynamic> subjects;
  final VoidCallback onComplete;
  const _LogRevisionForm({required this.subjects, required this.onComplete});

  @override
  ConsumerState<_LogRevisionForm> createState() => _LogRevisionFormState();
}

class _LogRevisionFormState extends ConsumerState<_LogRevisionForm> {
  dynamic _selectedSubject;
  String? _selectedChapter;
  dynamic _selectedTopic;
  List<dynamic> _subjectTopics = [];
  List<String> _chapters = [];
  List<dynamic> _chapterTopics = [];
  int _selectedDuration = 30;
  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
      _loadTopics(_selectedSubject.id!);
    }
  }

  Future<void> _loadTopics(int subjectId) async {
    final topics = await DatabaseHelper.instance.getTopicsWithRevisions(subjectId);
    if (!mounted) return;
    setState(() {
      _subjectTopics = topics;
      _chapters = topics.map((t) => t.chapter).toSet().where((c) => c.isNotEmpty).toList();
      _selectedChapter = _chapters.isNotEmpty ? _chapters.first : null;
      _updateTopics();
    });
  }

  void _updateTopics() {
    if (_selectedChapter != null) {
      _chapterTopics = _subjectTopics.where((t) => t.chapter == _selectedChapter).toList();
    } else {
      _chapterTopics = List.from(_subjectTopics);
    }
    _selectedTopic = _chapterTopics.isNotEmpty ? _chapterTopics.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.replay_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
          SizedBox(width: 10),
          Text('Log Revision Session',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        ]),
        SizedBox(height: 20),
        DropdownButtonFormField<dynamic>(
          decoration: _inputDeco('Select Subject'),
          value: _selectedSubject,
          items: widget.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() { _selectedSubject = val; _selectedChapter = null; _selectedTopic = null; _chapters = []; _chapterTopics = []; });
              _loadTopics(val.id!);
            }
          },
        ),
        SizedBox(height: 12),
        if (_chapters.isNotEmpty)
          DropdownButtonFormField<String>(
            decoration: _inputDeco('Select Chapter'),
            value: _selectedChapter,
            items: _chapters.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) { if (val != null) setState(() { _selectedChapter = val; _updateTopics(); }); },
          ),
        if (_chapters.isNotEmpty) SizedBox(height: 12),
        DropdownButtonFormField<dynamic>(
          decoration: _inputDeco('Select Topic'),
          value: _selectedTopic,
          items: _chapterTopics.map((t) => DropdownMenuItem(value: t, child: Text(t.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) { if (val != null) setState(() { _selectedTopic = val; }); },
        ),
        SizedBox(height: 20),
        Text('Duration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Wrap(spacing: 8, children: _durations.map((d) {
          final sel = _selectedDuration == d;
          return ChoiceChip(
            label: Text(d >= 60 ? '${d ~/ 60}h ${d % 60}m' : '${d}m'),
            selected: sel,
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).cardColor,
            labelStyle: TextStyle(color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
          );
        }).toList()),
        SizedBox(height: 24),
        Row(children: [
          Expanded(child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
          )),
          SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            onPressed: _selectedTopic == null ? null : () async {
              await DatabaseHelper.instance.addSession(StudySession(
                topicId: _selectedTopic!.id!,
                date: DateTime.now(),
                durationMinutes: _selectedDuration,
              ));
              widget.onComplete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Revision session logged!'),
                  duration: Duration(seconds: 2),
                ));
              }
            },
            child: Text('Log Revision', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label, filled: true, fillColor: AppColors.cardWhite,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
