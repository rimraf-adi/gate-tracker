import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterPills extends StatelessWidget {
  final int selectedIndex;
  final List<String> filters;
  final ValueChanged<int> onSelected;

  const FilterPills({
    required this.selectedIndex,
    required this.filters,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.asMap().entries.map((entry) {
            final idx = entry.key;
            final label = entry.value;
            final selected = idx == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: selected ? AppColors.lavenderPurple : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => onSelected(idx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
