import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class FullHeatmapScreen extends ConsumerWidget {
  const FullHeatmapScreen({super.key});

  Color _colorForMinutes(int minutes) {
    if (minutes == 0) return Colors.white.withValues(alpha: 0.05);
    final hours = minutes / 60.0;
    if (hours <= 0.5) return const Color(0xFF1A3A1A);
    if (hours <= 1) return const Color(0xFF2E5A2E);
    if (hours <= 2) return const Color(0xFF3D8B3D);
    if (hours <= 4) return const Color(0xFF5CAD5C);
    if (hours <= 8) return const Color(0xFF81C784);
    return const Color(0xFFA5D6A7);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(activityHeatmapProvider);
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, 1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Study Activity', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: heatmapAsync.when(
        data: (data) {
          // Group by month
          final Map<String, List<int>> monthly = {};
          for (var d = DateTime(startDate.year, startDate.month, 1); d.isBefore(DateTime(now.year, now.month + 1, 0)); d = DateTime(d.year, d.month + 1, 1)) {
            final key = DateFormat('MMMM yyyy').format(d);
            final daysInMonth = DateTime(d.year, d.month + 1, 0).day;
            final dailyMins = <int>[];
            for (var day = 1; day <= daysInMonth; day++) {
              final totalMin = data.entries
                  .where((e) => e.key.year == d.year && e.key.month == d.month && e.key.day == day)
                  .fold<int>(0, (prev, e) => prev + e.value);
              dailyMins.add(totalMin);
            }
            monthly[key] = dailyMins;
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: monthly.keys.length,
            itemBuilder: (context, i) {
              final monthKey = monthly.keys.elementAt(i);
              final days = monthly[monthKey]!;
              return Container(
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(monthKey,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    SizedBox(height: 12),
                    Wrap(
                      runSpacing: 4,
                      spacing: 4,
                      children: days.map((min) {
                        return Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: _colorForMinutes(min),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 4),
                    Text('${days.where((m) => m > 0).length} active days',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
