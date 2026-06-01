import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color color;

  const StatsRing({
    required this.progress,
    this.size = 48,
    this.color = AppColors.lavenderPurple,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Avoid displaying NaN if progress is somehow not valid
    final displayProgress = progress.isNaN || progress.isInfinite ? 0.0 : progress;
    final intPercent = (displayProgress * 100).clamp(0, 100).toInt();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: displayProgress,
            strokeWidth: size * 0.08,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '$intPercent%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.24,
                ),
          ),
        ],
      ),
    );
  }
}
