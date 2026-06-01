import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class ActivityHeatmap extends ConsumerStatefulWidget {
  final int weeksToDisplay;

  const ActivityHeatmap({
    super.key,
    this.weeksToDisplay = 26, // approx 6 months
  });

  @override
  ConsumerState<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends ConsumerState<ActivityHeatmap> {
  late DateTime _startDate;
  late DateTime _endDate;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    // Move back by weeksToDisplay, then to the previous Sunday
    final tempStart = _endDate.subtract(Duration(days: widget.weeksToDisplay * 7));
    final daysToSubtract = tempStart.weekday % 7; // Sunday is 0 for our math
    _startDate = tempStart.subtract(Duration(days: daysToSubtract));
    
    // Auto-scroll to the end after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Color _getColorForDuration(int durationMinutes) {
    if (durationMinutes == 0) return AppColors.lightGray.withValues(alpha: 0.5);
    if (durationMinutes < 30) return AppColors.limeGreen.withValues(alpha: 0.3);
    if (durationMinutes < 60) return AppColors.limeGreen.withValues(alpha: 0.6);
    if (durationMinutes < 120) return AppColors.limeGreen.withValues(alpha: 0.85);
    return const Color(0xFF2E7D32); // Deep green
  }

  @override
  Widget build(BuildContext context) {
    final heatmapAsync = ref.watch(activityHeatmapProvider(_startDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Study Activity (Last 6 Months)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        heatmapAsync.when(
          data: (data) {
            // Build the grid
            List<Widget> columns = [];
            DateTime currentDay = _startDate;
            
            // Month labels
            List<Widget> monthLabels = [];
            int lastMonth = -1;

            for (int w = 0; w <= widget.weeksToDisplay; w++) {
              List<Widget> daysInWeek = [];
              
              if (currentDay.month != lastMonth && currentDay.day <= 14) {
                monthLabels.add(Positioned(
                  left: w * 16.0,
                  child: Text(
                    DateFormat('MMM').format(currentDay),
                    style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                ));
                lastMonth = currentDay.month;
              }

              for (int d = 0; d < 7; d++) {
                if (currentDay.isAfter(_endDate)) {
                  daysInWeek.add(const SizedBox(width: 14, height: 14));
                } else {
                  final duration = data.entries
                      .where((e) =>
                          e.key.year == currentDay.year &&
                          e.key.month == currentDay.month &&
                          e.key.day == currentDay.day)
                      .fold<int>(0, (prev, e) => prev + e.value);

                  final color = _getColorForDuration(duration);
                  final label = duration > 0 ? '${duration}m on ${DateFormat('MMM d').format(currentDay)}' : 'No activity';

                  daysInWeek.add(
                    Tooltip(
                      message: label,
                      child: Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                }
                currentDay = currentDay.add(const Duration(days: 1));
              }

              columns.add(
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Column(
                    children: daysInWeek,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 16,
                    width: (widget.weeksToDisplay + 1) * 16.0,
                    child: Stack(children: monthLabels),
                  ),
                  const SizedBox(height: 4),
                  Row(children: columns),
                ],
              ),
            );
          },
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SizedBox(height: 120, child: Center(child: Text('Error: $e'))),
        ),
      ],
    );
  }
}
