import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/topic_note.dart';
import '../services/database_helper.dart';

class TopicNotesScreen extends ConsumerStatefulWidget {
  final int topicId;
  final String topicName;

  const TopicNotesScreen({
    required this.topicId,
    required this.topicName,
    super.key,
  });

  @override
  ConsumerState<TopicNotesScreen> createState() => _TopicNotesScreenState();
}

class _TopicNotesScreenState extends ConsumerState<TopicNotesScreen> {
  final _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  Future<String> _saveImageToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(p.join(appDir.path, 'topic_notes'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
    final destPath = p.join(notesDir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  void _showAddNoteSheet() {
    final textController = TextEditingController();
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.lavenderPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.note_add_rounded, color: AppColors.lavenderPurple, size: 24),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Add Note',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Text field
                    TextField(
                      controller: textController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write your note, annotation, or comment...',
                        hintStyle: TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: AppColors.warmIvory.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          borderSide: BorderSide(color: AppColors.lavenderPurple, width: 1.5),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Image preview
                    if (selectedImagePath != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.small),
                            child: Image.file(
                              File(selectedImagePath!),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedImagePath = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                    // Image picker buttons
                    Row(
                      children: [
                        _ImagePickerButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Gallery',
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1920,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              setModalState(() {
                                selectedImagePath = image.path;
                              });
                            }
                          },
                        ),
                        SizedBox(width: 12),
                        _ImagePickerButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Camera',
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 1920,
                              maxHeight: 1920,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              setModalState(() {
                                selectedImagePath = image.path;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Save / Cancel
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
                              final text = textController.text.trim();
                              if (text.isEmpty && selectedImagePath == null) return;

                              String? savedImagePath;
                              if (selectedImagePath != null) {
                                savedImagePath = await _saveImageToAppDir(selectedImagePath!);
                              }

                              final now = DateTime.now();
                              final note = TopicNote(
                                topicId: widget.topicId,
                                content: text,
                                imagePath: savedImagePath,
                                createdAt: now,
                                updatedAt: now,
                              );
                              await DatabaseHelper.instance.addNote(note);
                              ref.invalidate(topicNotesProvider(widget.topicId));
                              ref.invalidate(topicNoteCountProvider(widget.topicId));
                              ref.invalidate(totalNotesCountProvider);

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Note added!')),
                                );
                              }
                            },
                            child: Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditNoteSheet(TopicNote note) {
    final textController = TextEditingController(text: note.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Note',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: textController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Update your note...',
                    filled: true,
                    fillColor: AppColors.warmIvory.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                      borderSide: BorderSide(color: AppColors.lavenderPurple, width: 1.5),
                    ),
                  ),
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
                          final text = textController.text.trim();
                          if (text.isEmpty && note.imagePath == null) return;

                          final updated = note.copyWith(
                            content: text,
                            updatedAt: DateTime.now(),
                          );
                          await DatabaseHelper.instance.updateNote(updated);
                          ref.invalidate(topicNotesProvider(widget.topicId));

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteNote(TopicNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text('Delete Note?'),
        content: Text('This action cannot be undone.'),
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
      // Delete image file if exists
      if (note.imagePath != null) {
        final file = File(note.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await DatabaseHelper.instance.deleteNote(note.id!);
      ref.invalidate(topicNotesProvider(widget.topicId));
      ref.invalidate(topicNoteCountProvider(widget.topicId));
      ref.invalidate(totalNotesCountProvider);
    }
  }

  void _showFullImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(topicNotesProvider(widget.topicId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.neonPurple,
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: Text(
                'Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              background: Container(
                color: AppColors.neonPurple,
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.topicName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Annotations, comments & images',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
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
                // Height constraints to ensure Expanded works if we switch it
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              SizedBox(height: 20),
              // Notes list
              notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sticky_note_2_outlined, size: 64, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            'No notes yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap + to add your first annotation',
                            style: TextStyle(color: Colors.white24, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(
                        note: note,
                        dateFormat: _dateFormat,
                        onEdit: () => _showEditNoteSheet(note),
                        onDelete: () => _deleteNote(note),
                        onImageTap: note.imagePath != null
                            ? () => _showFullImage(note.imagePath!)
                            : null,
                      );
                    },
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
  floatingActionButton: FloatingActionButton(
    backgroundColor: AppColors.neonPurple,
    onPressed: _showAddNoteSheet,
    child: Icon(Icons.add, color: Theme.of(context).scaffoldBackgroundColor),
  ),
);
}
}

class _NoteCard extends StatelessWidget {
  final TopicNote note;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onImageTap;

  const _NoteCard({
    required this.note,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (note.imagePath != null)
              GestureDetector(
                onTap: onImageTap,
                child: Image.file(
                  File(note.imagePath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.white10,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 32),
                    ),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.content.isNotEmpty) ...[
                    Text(
                      note.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    SizedBox(height: 12),
                  ],
                  // Footer
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      SizedBox(width: 4),
                      Text(
                        dateFormat.format(note.createdAt),
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.neonPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: AppColors.neonPurple),
                              SizedBox(width: 4),
                              Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neonPurple)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.neonOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.neonOrange),
                              SizedBox(width: 4),
                              Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neonOrange)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.warmIvory.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.small),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.lavenderPurple),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.lavenderPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
