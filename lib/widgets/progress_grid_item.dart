import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/topic_progress.dart';

class ProgressGridItem extends StatelessWidget {
  final String label;
  final bool completed;
  final ProgressStatus status;
  final VoidCallback onTap;
  final VoidCallback? onNoteTap;
  final VoidCallback? onStrengthTap;
  final int noteCount;
  final String? strength;

  const ProgressGridItem({
    required this.label,
    required this.completed,
    required this.status,
    required this.onTap,
    this.onNoteTap,
    this.onStrengthTap,
    this.noteCount = 0,
    this.strength,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: completed ? AppColors.lavenderPurple.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.small),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? AppColors.lavenderPurple
                        : AppColors.lightGray,
                    border: completed
                        ? null
                        : Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: completed
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          decoration: completed ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white54,
                        ),
                  ),
                ),
                if (completed) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onStrengthTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: strength != null
                            ? _strengthColor(strength!).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: strength == null ? Border.all(color: Colors.white12) : null,
                      ),
                      child: Text(
                        strength ?? '+',
                        style: TextStyle(
                          color: strength != null ? _strengthColor(strength!) : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                if (noteCount > 0 || onNoteTap != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onNoteTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: noteCount > 0
                            ? AppColors.lavenderPurple.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            noteCount > 0 ? Icons.sticky_note_2_rounded : Icons.note_add_outlined,
                            size: 16,
                            color: noteCount > 0
                                ? AppColors.lavenderPurple
                                : Colors.white54,
                          ),
                          if (noteCount > 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              '$noteCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lavenderPurple,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _strengthColor(String s) {
    switch (s) {
      case 'strong':
        return const Color(0xFF4CAF50);
      case 'mid':
        return Colors.orange;
      case 'weak':
        return const Color(0xFFE57373);
      default:
        return Colors.white54;
    }
  }
}
