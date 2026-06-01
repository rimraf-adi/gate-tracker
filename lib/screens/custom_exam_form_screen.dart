import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/glass_card.dart';
import '../models/paper.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../services/syllabus_parser.dart';
import '../services/database_helper.dart';

class CustomExamFormScreen extends ConsumerStatefulWidget {
  const CustomExamFormScreen({super.key});

  @override
  ConsumerState<CustomExamFormScreen> createState() => _CustomExamFormScreenState();
}

class _CustomExamFormScreenState extends ConsumerState<CustomExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _syllabusController = TextEditingController();

  List<Subject> _parsedSubjects = [];
  List<List<Topic>> _parsedTopics = [];
  bool _showPreview = false;

  void _parseAndPreview() {
    if (_syllabusController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste some syllabus text first!')),
      );
      return;
    }

    final parser = SyllabusParser();
    final result = parser.parseCustomSyllabus(_syllabusController.text);
    setState(() {
      _parsedSubjects = result.subjects;
      _parsedTopics = result.topics;
      _showPreview = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_parsedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syllabus contains no subjects. Please parse a valid syllabus first.')),
      );
      return;
    }

    final db = DatabaseHelper.instance;
    final paperCode = _codeController.text.isNotEmpty
        ? _codeController.text.trim().toUpperCase()
        : 'CUSTOM-${DateTime.now().millisecondsSinceEpoch}';

    final paper = Paper(
      code: paperCode,
      fullName: _nameController.text.trim(),
      isCustom: true,
      syllabusSource: _syllabusController.text,
      sortOrder: 10, // put custom papers at the end
    );

    // Save paper, subjects, and topics in transaction
    final paperId = await db.insertPaper(paper);

    for (var i = 0; i < _parsedSubjects.length; i++) {
      final subject = _parsedSubjects[i].copyWith(paperId: paperId, sortOrder: i);
      final subjectId = await db.insertSubject(subject);

      for (var j = 0; j < _parsedTopics[i].length; j++) {
        final topic = _parsedTopics[i][j].copyWith(subjectId: subjectId, sortOrder: j);
        await db.insertTopic(topic);
      }
    }

    // Invalidate papers list and switch to the new custom paper
    ref.invalidate(allPapersProvider);
    ref.read(selectedPaperIdProvider.notifier).state = paperId;

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Custom syllabus "${paper.fullName}" created successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'New Exam',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
      ),
      body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Create Custom Exam',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Exam Full Name (e.g. BARC OCES)',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Exam Code (e.g. BARC) (Optional)',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Paste Syllabus Text',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Format: Use "Section 1 : Subject" to start a section, and write comma-separated topics on lines below.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _syllabusController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Section 1 : Engineering Mathematics\nLinear Algebra, Calculus, Probability\n\nSection 2 : Computer Networks\nLayering, Ethernet, TCP/IP Protocols',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                        ),
                        onPressed: _parseAndPreview,
                        icon: Icon(Icons.analytics_rounded),
                        label: Text('Parse & Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                if (_showPreview) ...[
                  SizedBox(height: 24),
                  Text(
                    'Preview & Verify',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap section titles or topics to edit them before saving.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  ..._buildPreviewList(),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lavenderPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                          ),
                          onPressed: _save,
                          child: Text('Save Custom Exam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPreviewList() {
    final widgets = <Widget>[];

    for (var i = 0; i < _parsedSubjects.length; i++) {
      final subjectIndex = i;
      final subject = _parsedSubjects[subjectIndex];
      final topics = _parsedTopics[subjectIndex];

      // Group topics of this subject by chapter
      final Map<String, List<int>> chapterToIndices = {};
      for (var j = 0; j < topics.length; j++) {
        final ch = topics[j].chapter.isEmpty ? 'General' : topics[j].chapter;
        chapterToIndices.putIfAbsent(ch, () => []).add(j);
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              shape: Border(),
              title: TextFormField(
                initialValue: subject.name,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.edit_rounded, size: 16, color: Colors.white54),
                ),
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                onChanged: (val) {
                  _parsedSubjects[subjectIndex] = subject.copyWith(name: val.trim());
                },
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                ...chapterToIndices.entries.map((entry) {
                  final chapterName = entry.key;
                  final indices = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          chapterName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.lavenderPurple,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...indices.map((topicIndex) {
                        final topic = topics[topicIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: Colors.white54),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: topic.name,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(fontSize: 14),
                                  onChanged: (val) {
                                    _parsedTopics[subjectIndex][topicIndex] = topic.copyWith(name: val.trim());
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _parsedTopics[subjectIndex].removeAt(topicIndex);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 12),
                    ],
                  );
                }),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _parsedTopics[subjectIndex].add(Topic(
                          subjectId: 0,
                          name: 'New Topic',
                          chapter: 'General',
                          sortOrder: _parsedTopics[subjectIndex].length,
                        ));
                      });
                    },
                    icon: Icon(Icons.add, size: 16, color: AppColors.lavenderPurple),
                    label: Text(
                      'Add Topic',
                      style: TextStyle(color: AppColors.lavenderPurple, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}
