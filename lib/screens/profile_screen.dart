import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/stats_ring.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showEditNameSheet() {
    final currentName = ref.read(userNameProvider);
    _nameController.text = currentName;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Name', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavenderPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  onPressed: () {
                    ref.read(userNameProvider.notifier).updateName(_nameController.text.trim());
                    Navigator.pop(ctx);
                  },
                  child: Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final papersAsync = ref.watch(allPapersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              SizedBox(height: 24),

              // Name card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.lavenderPurple,
                          shape: BoxShape.circle,
                        ),
                        child: Consumer(builder: (context, ref, _) {
                          final name = ref.watch(userNameProvider);
                          return Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          );
                        }),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Consumer(builder: (context, ref, _) {
                          final name = ref.watch(userNameProvider);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('GATE Aspirant', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          );
                        }),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_rounded, color: AppColors.lavenderPurple),
                        onPressed: _showEditNameSheet,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Quick actions
              SizedBox(height: 12),
              _GlobalStatsGrid(),
              SizedBox(height: 24),

              // Per-paper stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Paper Progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 12),
              papersAsync.when(
                data: (papers) => Column(
                  children: papers.map((p) => _PaperStatCard(paper: p)).toList(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              SizedBox(height: 24),



              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ActionRow(
                      icon: Icons.replay_rounded,
                      label: 'View Revision History',
                      onTap: () => Navigator.pushNamed(context, '/revision-history'),
                    ),
                    SizedBox(height: 8),
                    _ActionRow(
                      icon: Icons.history_rounded,
                      label: 'View Study History',
                      onTap: () => Navigator.pushNamed(context, '/session-history'),
                    ),
                    SizedBox(height: 8),
                    _ActionRow(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Create Custom Exam',
                      onTap: () => Navigator.pushNamed(context, '/add-custom-exam'),
                    ),
                    SizedBox(height: 8),
                    _ActionRow(
                      icon: Icons.restart_alt_rounded,
                      label: 'Reset All Progress',
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                            title: Text('Reset All Progress?'),
                            content: Text('This will clear all topic progress and study sessions. This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Reset'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await DatabaseHelper.instance.resetAllProgress();
                          ref.invalidate(allPapersProvider);
                          ref.invalidate(totalStudyHoursProvider);
                          ref.invalidate(totalStudySessionsCountProvider);
                          ref.invalidate(currentStreakProvider);
                          ref.invalidate(totalNotesCountProvider);
                          ref.invalidate(studySessionHistoryProvider);
                          ref.invalidate(studyHoursPerDayProvider(7));
                          ref.invalidate(activityHeatmapProvider);
                          ref.invalidate(allPapersCompletedTopicsProvider);
                          ref.invalidate(allPapersMockCountProvider);
                          ref.invalidate(allPapersMockAvgProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All progress has been reset.')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalStatsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursAsync = ref.watch(totalStudyHoursProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final notesAsync = ref.watch(totalNotesCountProvider);
    final sessionsAsync = ref.watch(totalStudySessionsCountProvider);
    final topicsAsync = ref.watch(allPapersCompletedTopicsProvider);
    final mocksCountAsync = ref.watch(allPapersMockCountProvider);
    final mocksAvgAsync = ref.watch(allPapersMockAvgProvider);

    final totalHours = hoursAsync.valueOrNull != null ? (hoursAsync.valueOrNull! / 60).round() : 0;
    final streak = streakAsync.valueOrNull ?? 0;
    final notes = notesAsync.valueOrNull ?? 0;
    final sessions = sessionsAsync.valueOrNull ?? 0;
    final topics = topicsAsync.valueOrNull ?? 0;
    final mocks = mocksCountAsync.valueOrNull ?? 0;
    final mockAvg = mocksAvgAsync.valueOrNull ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _MiniStatCard(icon: Icons.timer_rounded, value: '${totalHours}h', label: 'Study Hours', color: AppColors.lavenderPurple)),
              SizedBox(width: 10),
              Expanded(child: _MiniStatCard(icon: Icons.local_fire_department_rounded, value: '$streak', label: 'Day Streak', color: Colors.orange)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MiniStatCard(icon: Icons.check_circle_rounded, value: '$topics', label: 'Topics Done', color: const Color(0xFF4CAF50))),
              SizedBox(width: 10),
              Expanded(child: _MiniStatCard(icon: Icons.notes_rounded, value: '$notes', label: 'Notes', color: const Color(0xFF42A5F5))),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MiniStatCard(icon: Icons.menu_book_rounded, value: '$sessions', label: 'Sessions', color: AppColors.lavenderPurple)),
              SizedBox(width: 10),
              Expanded(child: _MiniStatCard(icon: Icons.quiz_rounded, value: mocks > 0 ? '$mocks' : '0', label: 'Mock Tests', color: Colors.orange)),
            ],
          ),
          SizedBox(height: 10),
          if (mocks > 0)
            Row(
              children: [
                Expanded(child: _MiniStatCard(icon: Icons.analytics_rounded, value: '${mockAvg.toStringAsFixed(0)}%', label: 'Mock Average', color: const Color(0xFF42A5F5))),
                SizedBox(width: 10),
                Expanded(child: _MiniStatCard(icon: Icons.assignment_turned_in_rounded, value: '—', label: 'Subjects', color: AppColors.lavenderPurple)),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface,
            surface.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PaperStatCard extends ConsumerWidget {
  final dynamic paper;

  const _PaperStatCard({required this.paper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(aggregateProgressProvider(paper.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 8),
      child: FutureBuilder(
        future: Future.wait([
          DatabaseHelper.instance.getCompletedSubjectsCount(paper.id),
          DatabaseHelper.instance.getTotalMockTestsCount(paper.id),
          DatabaseHelper.instance.getAverageMockScorePercentage(paper.id),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          final subjectsDone = snapshot.hasData ? snapshot.data![0] as int : 0;
          final mockCount = snapshot.hasData ? snapshot.data![1] as int : 0;
          final avgScore = snapshot.hasData ? (snapshot.data![2] as double) : 0.0;

          return GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(paper.code, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          if (paper.isCustom)
                            SizedBox(width: 8),
                          if (paper.isCustom)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.lavenderPurple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text('CUSTOM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.lavenderPurple)),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(paper.fullName, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _metricChip('$subjectsDone subjects done'),
                          SizedBox(width: 8),
                          _metricChip('$mockCount tests'),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                progressAsync.when(
                  data: (p) => StatsRing(progress: p, size: 48),
                  loading: () => SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3)),
                  error: (_, __) => SizedBox(width: 48, height: 48),
                ),
                if (mockCount > 0) ...[
                  SizedBox(width: 8),
                  Text('${avgScore.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.lavenderPurple)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: Colors.white70)),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.lavenderPurple, size: 22),
              SizedBox(width: 14),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500))),
              Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}


