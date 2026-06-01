import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/action_button.dart';
import '../widgets/progress_grid_item.dart';
import '../models/topic.dart';
import '../models/subject.dart';
import '../models/topic_progress.dart';
import '../models/study_session.dart';
import '../services/database_helper.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final int subjectId;

  const TopicDetailScreen({required this.subjectId, super.key});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  bool _isEditing = false;
  Topic? _recentlyDeletedTopic;
  ProgressStatus? _recentlyDeletedTopicStatus;

  Future<void> _showAddTopicDialog() async {
    final nameController = TextEditingController();
    final chapterController = TextEditingController();
    
    // Get existing chapters
    final db = DatabaseHelper.instance;
    final topics = await db.getTopicsBySubject(widget.subjectId);
    final existingChapters = topics.map((t) => t.chapter.isEmpty ? 'General' : t.chapter).toSet().toList();
    if (existingChapters.isEmpty) {
      existingChapters.add('General');
    }
    
    String selectedChapter = existingChapters.first;
    bool isNewChapter = false;

    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              title: Text('Add Topic'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Topic Name',
                        hintText: 'e.g. Asymptotic Notation',
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Chapter', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    if (!isNewChapter) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedChapter,
                        items: existingChapters.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedChapter = val;
                            });
                          }
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isNewChapter = true;
                          });
                        },
                        child: Text('+ Create New Chapter'),
                      ),
                    ] else ...[
                      TextField(
                        controller: chapterController,
                        decoration: const InputDecoration(
                          labelText: 'New Chapter Name',
                          hintText: 'e.g. Analysis of Algorithms',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isNewChapter = false;
                          });
                        },
                        child: Text('Use Existing Chapter'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavenderPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final chapter = isNewChapter ? chapterController.text.trim() : selectedChapter;
                    if (name.isNotEmpty && chapter.isNotEmpty) {
                      Navigator.pop(context, {'name': name, 'chapter': chapter});
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final name = result['name']!;
      final chapter = result['chapter']!;
      final newTopic = Topic(
        subjectId: widget.subjectId,
        name: name,
        chapter: chapter,
        sortOrder: topics.length,
      );
      await db.insertTopic(newTopic);
      ref.invalidate(topicsBySubjectProvider(widget.subjectId));
      
      // Update subject progress counts
      ref.invalidate(subjectProgressProvider(widget.subjectId));
      ref.invalidate(topicStrengthProvider(widget.subjectId));
      final paperId = ref.read(selectedPaperIdProvider);
      ref.invalidate(aggregateProgressProvider(paperId));
    }
  }

  Future<void> _showRenameDialog(Topic topic) async {
    final nameController = TextEditingController(text: topic.name);
    final chapterController = TextEditingController(text: topic.chapter);
    
    // Get existing chapters
    final db = DatabaseHelper.instance;
    final topics = await db.getTopicsBySubject(widget.subjectId);
    final existingChapters = topics.map((t) => t.chapter.isEmpty ? 'General' : t.chapter).toSet().toList();
    if (existingChapters.isEmpty) {
      existingChapters.add('General');
    }
    
    String selectedChapter = existingChapters.contains(topic.chapter) ? topic.chapter : existingChapters.first;
    bool isNewChapter = false;

    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              title: Text('Edit Topic'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Topic Name'),
                    ),
                    SizedBox(height: 16),
                    Text('Chapter', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    if (!isNewChapter) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedChapter,
                        items: existingChapters.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedChapter = val;
                            });
                          }
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isNewChapter = true;
                          });
                        },
                        child: Text('+ Create New Chapter'),
                      ),
                    ] else ...[
                      TextField(
                        controller: chapterController,
                        decoration: const InputDecoration(
                          labelText: 'New Chapter Name',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isNewChapter = false;
                          });
                        },
                        child: Text('Use Existing Chapter'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavenderPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final chapter = isNewChapter ? chapterController.text.trim() : selectedChapter;
                    if (name.isNotEmpty && chapter.isNotEmpty) {
                      Navigator.pop(context, {'name': name, 'chapter': chapter});
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final name = result['name']!;
      final chapter = result['chapter']!;
      if (name != topic.name || chapter != topic.chapter) {
        await db.updateTopic(topic.copyWith(name: name, chapter: chapter));
        ref.invalidate(topicsBySubjectProvider(widget.subjectId));
      }
    }
  }

  Future<void> _deleteTopic(Topic topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text('Delete Topic?'),
        content: Text('Are you sure you want to delete "${topic.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = DatabaseHelper.instance;
      _recentlyDeletedTopic = topic;
      final prog = await db.getProgress(topic.id!);
      _recentlyDeletedTopicStatus = prog?.status;

      await db.deleteTopic(topic.id!);
      ref.invalidate(topicsBySubjectProvider(widget.subjectId));
      ref.invalidate(subjectProgressProvider(widget.subjectId));
      ref.invalidate(topicStrengthProvider(widget.subjectId));
      ref.invalidate(topicStrengthDetailsProvider(widget.subjectId));
      final paperId = ref.read(selectedPaperIdProvider);
      ref.invalidate(aggregateProgressProvider(paperId));
      ref.invalidate(completedTopicsTodayProvider);
      ref.invalidate(totalCompletedTopicsProvider(paperId));
      ref.invalidate(completedSubjectsCountProvider(paperId));

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${topic.name}"'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.limeGreen,
              onPressed: () async {
                if (_recentlyDeletedTopic != null) {
                  final newTopicId = await db.insertTopic(_recentlyDeletedTopic!);
                  if (_recentlyDeletedTopicStatus != null) {
                    await db.setProgress(newTopicId, _recentlyDeletedTopicStatus!);
                  }
                  ref.invalidate(topicsBySubjectProvider(widget.subjectId));
                  ref.invalidate(subjectProgressProvider(widget.subjectId));
                  ref.invalidate(topicStrengthProvider(widget.subjectId));
                  ref.invalidate(topicStrengthDetailsProvider(widget.subjectId));
                  ref.invalidate(aggregateProgressProvider(paperId));
                  ref.invalidate(completedTopicsTodayProvider);
                  ref.invalidate(totalCompletedTopicsProvider(paperId));
                  ref.invalidate(completedSubjectsCountProvider(paperId));
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<int?> _showDurationDialog(BuildContext context) async {
    int selected = 30;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          title: Text('Mark as Completed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How long did you study this topic?',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              SizedBox(height: 16),
              Wrap(spacing: 8, children: [15, 30, 45, 60, 90, 120].map((d) {
                final sel = selected == d;
                return ChoiceChip(
                  label: Text(d >= 60 ? '${d ~/ 60}h ${d % 60}m' : '${d}m'),
                  selected: sel,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => setState(() => selected = d),
                );
              }).toList()),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              onPressed: () => Navigator.pop(ctx, selected),
              child: Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  void _showLogStudySheet(List<Topic> topics) {
    if (topics.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) {
        return _LogStudyForm(topics: topics);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsBySubjectProvider(widget.subjectId));
    final progressAsync = ref.watch(subjectProgressProvider(widget.subjectId));
    final paperId = ref.watch(selectedPaperIdProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.neonLime,
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_rounded),
                color: Colors.white,
                iconSize: 26,
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
              ),
              SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: FutureBuilder<Subject?>(
                future: DatabaseHelper.instance.getSubjectById(widget.subjectId),
                builder: (context, snapshot) {
                  final subjectName = snapshot.data?.name ?? 'Loading...';
                  return Text(
                    subjectName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  );
                },
              ),
              background: Container(
                color: AppColors.neonLime,
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEditing)
                      progressAsync.when(
                        data: (progress) {
                          final completed = progress['completed'] ?? 0;
                          final total = progress['total'] ?? 0;
                          final ratio = total > 0 ? completed / total : 0.0;

                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white12,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.assignment_turned_in_rounded, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$completed / $total topics',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    '${(ratio * 100).toStringAsFixed(0)}% Completed',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

              SizedBox(height: 16),

              // Action buttons (Log Study button)
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: topicsAsync.when(
                    data: (topics) => ActionButton(
                      label: 'Log Study Session',
                      icon: Icons.add_rounded,
                      onTap: () => _showLogStudySheet(topics),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

              SizedBox(height: 16),

              // Topics List
              topicsAsync.when(
                data: (topics) {
                  if (topics.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No topics in this subject.',
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ),
                    );
                  }

                  final strengthAsync = ref.watch(topicStrengthDetailsProvider(widget.subjectId));
                  final strengthMap = <int, String?>{};
                  final details = strengthAsync.valueOrNull ?? [];
                  for (final d in details) {
                    strengthMap[d['id'] as int] = d['strength'] as String?;
                  }

                  // Group topics by chapter
                  final chapterGroups = <String, List<Topic>>{};
                  for (final topic in topics) {
                    final ch = topic.chapter.isEmpty ? 'General' : topic.chapter;
                    chapterGroups.putIfAbsent(ch, () => []).add(topic);
                  }

                  return ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 100),
                    children: chapterGroups.entries.map((entry) {
                      final chapterName = entry.key;
                      final chapterTopics = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chapterName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 12),
                            if (_isEditing)
                              ...chapterTopics.map((topic) {
                                final String? strength = strengthMap[topic.id];
                                return Container(
                                  key: ValueKey(topic.id),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.drag_indicator_rounded, color: Colors.white54, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(topic.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                                      ),
                                      _StrengthBadge(strength, topicId: topic.id!, subjectId: widget.subjectId),
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                        onPressed: () => _showRenameDialog(topic),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        onPressed: () => _deleteTopic(topic),
                                      ),
                                    ],
                                  ),
                                );
                              })
                            else
                              ...chapterTopics.map((topic) {
                                final String? strength = strengthMap[topic.id];
                                final progressState = ref.watch(topicProgressProvider(topic.id!));
                                final noteCountAsync = ref.watch(topicNoteCountProvider(topic.id!));
                                final noteCount = noteCountAsync.valueOrNull ?? 0;
                                return ProgressGridItem(
                                  label: topic.name,
                                  completed: progressState == ProgressStatus.completed,
                                  status: progressState,
                                  strength: strength,
                                  noteCount: noteCount,
                                  onTap: () async {
                                    final topicId = topic.id!;
                                    final progress = ref.read(topicProgressProvider(topicId));
                                    if (progress == ProgressStatus.pending) {
                                      final dur = await _showDurationDialog(context);
                                      if (dur != null && context.mounted) {
                                        ref.read(topicProgressProvider(topicId).notifier)
                                            .toggle(subjectId: widget.subjectId, paperId: paperId, durationMinutes: dur);
                                      }
                                    } else {
                                      ref.read(topicProgressProvider(topicId).notifier)
                                          .toggle(subjectId: widget.subjectId, paperId: paperId);
                                    }
                                  },
                                  onNoteTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/topic-notes',
                                      arguments: {'topicId': topic.id!, 'topicName': topic.name},
                                    );
                                  },
                                  onStrengthTap: () async {
                                    final next = strength == null || strength == 'weak' ? 'strong' : strength == 'strong' ? 'mid' : 'weak';
                                    await DatabaseHelper.instance.setManualStrength(topic.id!, next);
                                    ref.invalidate(topicStrengthDetailsProvider(widget.subjectId));
                                    ref.invalidate(topicStrengthProvider(widget.subjectId));
                                    ref.invalidate(subjectProgressProvider(widget.subjectId));
                                  },
                                );
                              }),
                          ],
                        ),
                      );
                    }).toList(),
                  );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
            ],
          ),
        ),
      ),
    ),
    ],
  ),
  floatingActionButton: _isEditing
          ? FloatingActionButton(
              backgroundColor: AppColors.neonLime,
              mini: true,
              onPressed: _showAddTopicDialog,
              child: Icon(Icons.add, color: Theme.of(context).scaffoldBackgroundColor),
            )
          : null,
    );
  }
}

class _StrengthBadge extends ConsumerWidget {
  final String? strength;
  final int topicId;
  final int subjectId;

  const _StrengthBadge(this.strength, {required this.topicId, required this.subjectId});

  String? _next(String? current) {
    if (current == null || current == 'weak') return 'strong';
    if (current == 'strong') return 'mid';
    if (current == 'mid') return 'weak';
    return 'strong';
  }

  Color _color(String? s) {
    switch (s) {
      case 'strong': return const Color(0xFF4CAF50);
      case 'mid': return Colors.orange;
      case 'weak': return const Color(0xFFE57373);
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = strength;
    final color = display != null ? _color(display) : Colors.white38;

    return GestureDetector(
      onTap: () async {
        final next = _next(display);
        await DatabaseHelper.instance.setManualStrength(topicId, next);
        ref.invalidate(topicStrengthDetailsProvider(subjectId));
        ref.invalidate(topicStrengthProvider(subjectId));
        ref.invalidate(subjectProgressProvider(subjectId));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: display != null ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: display == null ? Border.all(color: Colors.white12) : null,
        ),
        child: Text(
          display ?? '+',
          style: TextStyle(color: display != null ? color : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _LogStudyForm extends ConsumerStatefulWidget {
  final List<Topic> topics;

  const _LogStudyForm({required this.topics});

  @override
  ConsumerState<_LogStudyForm> createState() => _LogStudyFormState();
}

class _LogStudyFormState extends ConsumerState<_LogStudyForm> {
  late int _selectedTopicId;
  int _selectedDuration = 30; // default 30 mins
  final List<int> _durations = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _selectedTopicId = widget.topics.first.id!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Study Session',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          SizedBox(height: 20),
          Text(
            'Select Topic',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            initialValue: _selectedTopicId,
            items: widget.topics.map((t) {
              return DropdownMenuItem<int>(
                value: t.id,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Text(t.name, overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedTopicId = val;
                });
              }
            },
          ),
          SizedBox(height: 20),
          Text(
            'Study Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durations.map((d) {
              final isSelected = _selectedDuration == d;
              final label = d >= 60 ? '${d ~/ 60}h ${d % 60 > 0 ? '${d % 60}m' : ''}' : '${d}m';
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: AppColors.lavenderPurple,
                backgroundColor: Theme.of(context).cardColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                onSelected: (_) {
                  setState(() {
                    _selectedDuration = d;
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavenderPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  onPressed: () async {
                    final session = StudySession(
                      topicId: _selectedTopicId,
                      date: DateTime.now(),
                      durationMinutes: _selectedDuration,
                    );
                    await DatabaseHelper.instance.addSession(session);
                    ref.invalidate(studyHoursPerDayProvider(7));
                    ref.invalidate(activityHeatmapProvider);
                    ref.invalidate(weakTopicsProvider(ref.read(selectedPaperIdProvider)));
                    ref.invalidate(totalStudyHoursProvider);
                    ref.invalidate(totalStudySessionsCountProvider);
                    ref.invalidate(currentStreakProvider);
                    ref.invalidate(studySessionHistoryProvider);
                    ref.invalidate(allPapersCompletedTopicsProvider);
                    ref.invalidate(allPapersMockCountProvider);
                    ref.invalidate(allPapersMockAvgProvider);
                    ref.invalidate(completedTopicsTodayProvider);
                    ref.invalidate(revisionHistoryProvider(ref.read(selectedPaperIdProvider)));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Study session logged successfully!')),
                      );
                    }
                  },
                  child: Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}
