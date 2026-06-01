import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(studySessionHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Study History', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: historyAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No study sessions yet', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Log your first study session to see history', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }

          final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + (s['duration_minutes'] as int? ?? 0));

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${sessions.length} sessions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('${(totalMinutes / 60).toStringAsFixed(1)} hours total', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    final topicName = s['topic_name'] as String? ?? 'Unknown';
                    final subjectName = s['subject_name'] as String? ?? '';
                    final paperCode = s['paper_code'] as String? ?? '';
                    final duration = s['duration_minutes'] as int? ?? 0;
                    final dateStr = s['date'] as String? ?? '';
                    final date = DateTime.tryParse(dateStr);
                    final formatted = date != null ? DateFormat('MMM d, yyyy  h:mm a').format(date) : dateStr;
                    final label = duration >= 60
                        ? '${duration ~/ 60}h ${duration % 60 > 0 ? '${duration % 60}m' : ''}'
                        : '${duration}m';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.lavenderPurple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.menu_book_rounded, color: AppColors.lavenderPurple, size: 20),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(topicName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                SizedBox(height: 2),
                                Text('$subjectName  ·  $paperCode', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                                Text(formatted, style: TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.lavenderPurple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(label, style: TextStyle(color: AppColors.lavenderPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
