import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class RevisionHistoryScreen extends ConsumerWidget {
  const RevisionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final historyAsync = ref.watch(revisionHistoryProvider(paperId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Revision History', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: historyAsync.when(
        data: (revisions) {
          if (revisions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                  SizedBox(height: 16),
                  Text('No revisions yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Complete topics to schedule revisions', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: revisions.length,
            itemBuilder: (context, i) {
              final r = revisions[i];
              final topicName = r['topic_name'] as String? ?? 'Unknown';
              final subjectName = r['subject_name'] as String? ?? '';
              final paperCode = r['paper_code'] as String? ?? '';
              final attempts = r['attempts'] as int? ?? 0;
              final interval = r['interval_days'] as int? ?? 0;
              final scheduled = r['scheduled_date'] as String?;
              final scheduledDate = scheduled != null ? DateTime.tryParse(scheduled) : null;
              final completedStr = r['completed_date'] as String?;
              final completedDate = completedStr != null ? DateTime.tryParse(completedStr) : null;
              final isOverdue = completedDate == null && scheduledDate != null && scheduledDate.isBefore(DateTime.now());

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: isOverdue ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: completedDate != null
                                ? const Color(0xFF4CAF50)
                                : isOverdue
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(topicName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('$attempts attempt${attempts != 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text('$subjectName  ·  $paperCode',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        SizedBox(width: 4),
                        Text(
                          completedDate != null
                              ? 'Completed ${DateFormat('MMM d').format(completedDate)}'
                              : 'Scheduled ${DateFormat('MMM d').format(scheduledDate!)} · Every $interval day${interval != 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        ),
                        if (isOverdue) ...[SizedBox(width: 8), Text('Overdue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
