import 'package:flutter/material.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(icon: Icons.home_rounded, isSelected: currentIndex == 0, onTap: () => onTap(0), colors: colors),
            _buildNavItem(icon: Icons.assignment_rounded, isSelected: currentIndex == 1, onTap: () => onTap(1), colors: colors),
            _buildNavItem(icon: Icons.replay_rounded, isSelected: currentIndex == 2, onTap: () => onTap(2), colors: colors),
            _buildNavItem(icon: Icons.person_outline_rounded, isSelected: currentIndex == 3, onTap: () => onTap(3), colors: colors),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.onSurface.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.4),
          size: 24,
        ),
      ),
    );
  }
}
