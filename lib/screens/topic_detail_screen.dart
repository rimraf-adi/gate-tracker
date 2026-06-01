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
              title: const Text('Add Topic'),
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
                    const SizedBox(height: 16),
                    const Text('Chapter', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
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
                        child: const Text('+ Create New Chapter'),
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
                        child: const Text('Use Existing Chapter'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                  child: const Text('Save'),
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
              title: const Text('Edit Topic'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Topic Name'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Chapter', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
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
                        child: const Text('+ Create New Chapter'),
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
                        child: const Text('Use Existing Chapter'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                  child: const Text('Save'),
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
        title: const Text('Delete Topic?'),
        content: Text('Are you sure you want to delete "${topic.name}"?'),
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
      _recentlyDeletedTopic = topic;
      final prog = await db.getProgress(topic.id!);
      _recentlyDeletedTopicStatus = prog?.status;

      await db.deleteTopic(topic.id!);
      ref.invalidate(topicsBySubjectProvider(widget.subjectId));
      ref.invalidate(subjectProgressProvider(widget.subjectId));
      final paperId = ref.read(selectedPaperIdProvider);
      ref.invalidate(aggregateProgressProvider(paperId));

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
                  ref.invalidate(aggregateProgressProvider(paperId));
                }
              },
            ),
          ),
        );
      }
    }
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
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.neonLime,
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_rounded),
                color: Colors.black87,
                iconSize: 26,
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: FutureBuilder<Subject?>(
                future: DatabaseHelper.instance.getSubjectById(widget.subjectId),
                builder: (context, snapshot) {
                  final subjectName = snapshot.data?.name ?? 'Loading...';
                  return Text(
                    subjectName,
                    style: const TextStyle(
                      color: Colors.black87,
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
                                  color: Colors.black12,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.black87),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$completed / $total topics',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    '${(ratio * 100).toStringAsFixed(0)}% Completed',
                                    style: const TextStyle(
                                      color: Colors.black54,
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
                decoration: const BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

              // Topics List
              Expanded(
                child: topicsAsync.when(
                  data: (topics) {
                    if (topics.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No topics in this subject.',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            if (_isEditing)
                              ElevatedButton(
                                onPressed: _showAddTopicDialog,
                                child: const Text('Add First Topic'),
                              ),
                          ],
                        ),
                      );
                    }

                    // Grouping topics by chapter
                    final Map<String, List<Topic>> chapters = {};
                    for (final topic in topics) {
                      final ch = topic.chapter.isEmpty ? 'General' : topic.chapter;
                      chapters.putIfAbsent(ch, () => []).add(topic);
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 100),
                      children: chapters.entries.map((entry) {
                        final chapterName = entry.key;
                        final chapterTopics = entry.value;

                        // Calculate completed count
                        int completedCount = 0;
                        for (final t in chapterTopics) {
                          final progress = ref.watch(topicProgressProvider(t.id!));
                          if (progress == ProgressStatus.completed) {
                            completedCount++;
                          }
                        }
                        final totalCount = chapterTopics.length;
                        final ratio = totalCount > 0 ? completedCount / totalCount : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Chapter Header
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chapterName,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textWhite,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonPurple.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Text(
                                        '$completedCount / $totalCount',
                                        style: const TextStyle(
                                          color: AppColors.neonPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor: AppColors.darkBackground,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonPurple),
                                    minHeight: 4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_isEditing)
                                  ReorderableListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: chapterTopics.length,
                                    onReorderItem: (oldIndex, newIndex) async {
                                      final updatedList = List<Topic>.from(chapterTopics);
                                      final item = updatedList.removeAt(oldIndex);
                                      updatedList.insert(newIndex, item);

                                      for (var idx = 0; idx < updatedList.length; idx++) {
                                        await DatabaseHelper.instance.updateTopic(
                                          updatedList[idx].copyWith(sortOrder: idx),
                                        );
                                      }
                                      ref.invalidate(topicsBySubjectProvider(widget.subjectId));
                                    },
                                    itemBuilder: (context, idx) {
                                      final topic = chapterTopics[idx];
                                      return Container(
                                        key: ValueKey(topic.id),
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.drag_indicator_rounded, color: Colors.black38, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                topic.name,
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
                                              onPressed: () => _showRenameDialog(topic),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                              onPressed: () => _deleteTopic(topic),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                else
                                  ...chapterTopics.map((topic) {
                                    final progressState = ref.watch(topicProgressProvider(topic.id!));
                                    final noteCountAsync = ref.watch(topicNoteCountProvider(topic.id!));
                                    final noteCount = noteCountAsync.valueOrNull ?? 0;
                                    return ProgressGridItem(
                                      label: topic.name,
                                      completed: progressState == ProgressStatus.completed,
                                      status: progressState,
                                      noteCount: noteCount,
                                      onTap: () {
                                        ref
                                            .read(topicProgressProvider(topic.id!).notifier)
                                            .toggle(subjectId: widget.subjectId, paperId: paperId);
                                      },
                                      onNoteTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/topic-notes',
                                          arguments: {'topicId': topic.id!, 'topicName': topic.name},
                                        );
                                      },
                                    );
                                  }),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
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
              child: const Icon(Icons.add, color: AppColors.darkBackground),
            )
          : null,
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
          const SizedBox(height: 20),
          Text(
            'Select Topic',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
                borderSide: const BorderSide(color: AppColors.lightGray),
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
          const SizedBox(height: 20),
          Text(
            'Study Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
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
                backgroundColor: AppColors.cardWhite,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
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
                    
                    // Invalidate analytics so they update on next visit
                    ref.invalidate(studyHoursPerDayProvider(7));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Study session logged successfully!')),
                      );
                    }
                  },
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
