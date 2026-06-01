import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';

class ActivityHeatmap extends ConsumerStatefulWidget {
  const ActivityHeatmap({super.key});

  @override
  ConsumerState<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends ConsumerState<ActivityHeatmap> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  Color _colorForMinutes(int minutes) {
    if (minutes == 0) return Colors.white.withValues(alpha: 0.06);
    final hours = minutes / 60.0;
    if (hours <= 0.5) return const Color(0xFF1A3A1A);
    if (hours <= 1) return const Color(0xFF2E5A2E);
    if (hours <= 2) return const Color(0xFF3D8B3D);
    if (hours <= 4) return const Color(0xFF5CAD5C);
    if (hours <= 8) return const Color(0xFF81C784);
    return const Color(0xFFA5D6A7);
  }

  @override
  Widget build(BuildContext context) {
    final heatmapAsync = ref.watch(activityHeatmapProvider);
    final now = DateTime.now();
    final canGoNext = _viewMonth.year < now.year || (_viewMonth.year == now.year && _viewMonth.month < now.month);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title + month navigation
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/full-heatmap'),
              child: Text('Study Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: canGoNext
                  ? () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1))
                  : null,
              child: Icon(Icons.chevron_left_rounded, size: 20,
                color: canGoNext ? Colors.white54 : Colors.white10),
            ),
            SizedBox(width: 4),
            Text(DateFormat('MMM yyyy').format(_viewMonth),
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)),
              child: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white54),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: heatmapAsync.when(
            data: (data) {
              final cells = <Widget>[];
              for (var day = 1; day <= daysInMonth; day++) {
                final totalMin = data.entries
                    .where((e) =>
                        e.key.year == _viewMonth.year &&
                        e.key.month == _viewMonth.month &&
                        e.key.day == day)
                    .fold<int>(0, (prev, e) => prev + e.value);
                final color = _colorForMinutes(totalMin);
                final label = totalMin > 0
                    ? '${(totalMin / 60).toStringAsFixed(1)}h — ${DateFormat('MMM d').format(DateTime(_viewMonth.year, _viewMonth.month, day))}'
                    : DateFormat('MMM d — no activity').format(DateTime(_viewMonth.year, _viewMonth.month, day));

                cells.add(
                  Tooltip(
                    message: label,
                    child: Container(
                      width: 16, height: 16,
                      margin: const EdgeInsets.only(right: 4, bottom: 4),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(runSpacing: 0, children: cells),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Less', style: TextStyle(color: Colors.white38, fontSize: 9)),
                      SizedBox(width: 4),
                      ...[0, 0.5, 1, 2, 4, 8].map((h) => Container(
                        width: 14, height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: _colorForMinutes((h * 60).round()), borderRadius: BorderRadius.circular(3)),
                      )),
                      SizedBox(width: 4),
                      Text('More', style: TextStyle(color: Colors.white38, fontSize: 9)),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/full-heatmap'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 11, color: Colors.white38),
                            SizedBox(width: 3),
                            Text('Full history', style: TextStyle(color: Colors.white38, fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e', style: TextStyle(color: Colors.white38, fontSize: 12))),
          ),
        ),
      ],
    );
  }
}
