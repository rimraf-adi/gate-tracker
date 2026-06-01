import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/stats_ring.dart';
import '../widgets/paper_chip.dart';
import '../models/subject.dart';
import '../models/paper.dart';
import '../services/database_helper.dart';
import '../services/syllabus_loader.dart';
import '../models/topic.dart';
import '../models/topic_progress.dart';

class SubjectListScreen extends ConsumerStatefulWidget {
  const SubjectListScreen({super.key});

  @override
  ConsumerState<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends ConsumerState<SubjectListScreen> {
  bool _isEditing = false;
  Subject? _recentlyDeletedSubject;
  List<Map<String, dynamic>>? _recentlyDeletedTopicsData; // To store topics under deleted subject

  String _emojiFor(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('math')) return '📐';
    if (nameLower.contains('digital')) return '💻';
    if (nameLower.contains('computer org') || nameLower.contains('architecture') || nameLower.contains('coa')) return '🖥️';
    if (nameLower.contains('program') || nameLower.contains('data structure') || nameLower.contains(' c ')) return '👨‍💻';
    if (nameLower.contains('algo')) return '⚙️';
    if (nameLower.contains('theory') || nameLower.contains('toc') || nameLower.contains('computation')) return '🔬';
    if (nameLower.contains('compiler')) return '🔧';
    if (nameLower.contains('operating') || nameLower.contains('os')) return '⚡';
    if (nameLower.contains('database') || nameLower.contains('db') || nameLower.contains('sql')) return '🗄️';
    if (nameLower.contains('network')) return '🌐';
    if (nameLower.contains('signal') || nameLower.contains('system')) return '📡';
    if (nameLower.contains('device') || nameLower.contains('electron') || nameLower.contains('semiconductor')) return '🔌';
    if (nameLower.contains('analog') || nameLower.contains('circuit')) return '⚡';
    if (nameLower.contains('control')) return '🎛️';
    if (nameLower.contains('comm')) return '📶';
    if (nameLower.contains('electromag')) return '🧲';
    return '📖';
  }

  Future<void> _showAddSubjectDialog(int paperId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Add Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Subject Name (e.g. Linear Algebra)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lavenderPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final db = DatabaseHelper.instance;
      final subjects = await db.getSubjectsByPaper(paperId);
      final newSubject = Subject(
        paperId: paperId,
        name: name,
        sortOrder: subjects.length,
      );
      await db.insertSubject(newSubject);
      ref.invalidate(subjectsByPaperProvider(paperId));
    }
  }

  Future<void> _showRenameDialog(Subject subject) async {
    final controller = TextEditingController(text: subject.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Rename Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new subject name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lavenderPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != subject.name) {
      final db = DatabaseHelper.instance;
      await db.updateSubject(subject.copyWith(name: newName));
      ref.invalidate(subjectsByPaperProvider(subject.paperId));
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Delete Subject?'),
        content: Text('Are you sure you want to delete "${subject.name}"? This deletes all its topics and progress.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = DatabaseHelper.instance;
      
      // Keep deleted data in memory for Undo action
      _recentlyDeletedSubject = subject;
      final topics = await db.getTopicsBySubject(subject.id!);
      _recentlyDeletedTopicsData = [];
      for (final t in topics) {
        final prog = await db.getProgress(t.id!);
        _recentlyDeletedTopicsData!.add({
          'topic': t,
          'status': prog?.status,
        });
      }

      await db.deleteSubject(subject.id!);
      ref.invalidate(subjectsByPaperProvider(subject.paperId));

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${subject.name}"'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.limeGreen,
              onPressed: () async {
                if (_recentlyDeletedSubject != null) {
                  final newSubId = await db.insertSubject(_recentlyDeletedSubject!);
                  if (_recentlyDeletedTopicsData != null) {
                    for (final data in _recentlyDeletedTopicsData!) {
                      final topic = (data['topic'] as Topic).copyWith(subjectId: newSubId);
                      final newTopicId = await db.insertTopic(topic);
                      final status = data['status'] as ProgressStatus?;
                      if (status != null) {
                        await db.setProgress(newTopicId, status);
                      }
                    }
                  }
                  ref.invalidate(subjectsByPaperProvider(subject.paperId));
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _resetToDefault(Paper paper) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Reset Syllabus?'),
        content: Text('This will delete all custom edits, reorderings, and added subjects in ${paper.fullName} and reset to the original GATE syllabus. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lavenderPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isEditing = false;
      });
      await SyllabusLoader.instance.loadSingle(paper.code);
      ref.invalidate(allPapersProvider);
      ref.invalidate(subjectsByPaperProvider(paper.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset ${paper.code} syllabus to default!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final subjectsAsync = ref.watch(subjectsByPaperProvider(paperId));
    final papersAsync = ref.watch(allPapersProvider);

    Paper? currentPaper;
    papersAsync.whenData((papers) {
      currentPaper = papers.firstWhere((p) => p.id == paperId, orElse: () => papers.first);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Subjects',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
            IconButton(
                icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_rounded),
                color: _isEditing ? AppColors.lavenderPurple : AppColors.textWhite,
                iconSize: 26,
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
              ),
              if (currentPaper != null && !currentPaper!.isCustom)
                IconButton(
                  icon: const Icon(Icons.restore_rounded),
                  color: AppColors.textWhite,
                  iconSize: 26,
                  onPressed: () => _resetToDefault(currentPaper!),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Paper switcher chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const PaperChip(),
                  if (_isEditing) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Editing Mode',
                      style: TextStyle(
                        color: AppColors.lavenderPurple.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: subjectsAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No subjects found.',
                            style: TextStyle(fontSize: 16, color: AppColors.textGray),
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            ElevatedButton(
                              onPressed: () => _showAddSubjectDialog(paperId),
                              child: const Text('Add First Subject'),
                            ),
                        ],
                      ),
                    );
                  }

                  if (_isEditing) {
                    return ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: subjects.length,
                      onReorderItem: (oldIndex, newIndex) async {
                        final updatedList = List<Subject>.from(subjects);
                        final item = updatedList.removeAt(oldIndex);
                        updatedList.insert(newIndex, item);

                        final ids = updatedList.map((s) => s.id!).toList();
                        await DatabaseHelper.instance.reorderSubjects(ids);
                        ref.invalidate(subjectsByPaperProvider(paperId));
                      },
                      itemBuilder: (context, i) {
                        final subject = subjects[i];
                        return _buildEditableSubjectCard(subject);
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: subjects.length,
                    itemBuilder: (context, i) {
                      final subject = subjects[i];
                      return _buildSubjectCard(subject);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              backgroundColor: AppColors.lavenderPurple,
              mini: true,
              onPressed: () => _showAddSubjectDialog(paperId),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    final progressAsync = ref.watch(subjectProgressProvider(subject.id!));

    return progressAsync.when(
      data: (progress) {
        final completed = progress['completed'] ?? 0;
        final total = progress['total'] ?? 0;
        final ratio = total > 0 ? completed / total : 0.0;

        return GlassCard(
          onTap: () {
            Navigator.pushNamed(context, '/topics', arguments: subject.id);
          },
          child: Row(
            children: [
              Text(_emojiFor(subject.name), style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 4),
                      Text(
                        '$completed / $total topics completed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textGray),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatsRing(progress: ratio),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEditableSubjectCard(Subject subject) {
    return Container(
      key: ValueKey(subject.id),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator_rounded, color: Colors.white38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subject.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white54),
              onPressed: () => _showRenameDialog(subject),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _deleteSubject(subject),
            ),
          ],
        ),
      ),
    );
  }
}
