import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class PaperChip extends ConsumerWidget {
  const PaperChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(allPapersProvider);
    final selectedPaperId = ref.watch(selectedPaperIdProvider);

    return papersAsync.when(
      data: (papers) {
        if (papers.isEmpty) return const SizedBox.shrink();

        final selectedPaper = papers.firstWhere(
          (p) => p.id == selectedPaperId,
          orElse: () => papers.first,
        );

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: PopupMenuButton<int>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            offset: const Offset(0, 48),
            onSelected: (id) {
              if (id == -1) {
                Navigator.pushNamed(context, '/add-custom-exam');
              } else {
                ref.read(selectedPaperIdProvider.notifier).state = id;
              }
            },
            itemBuilder: (context) {
              return [
                ...papers.map((p) => PopupMenuItem<int>(
                      value: p.id,
                      child: Row(
                        children: [
                          Icon(
                            p.isCustom ? Icons.edit_note_rounded : Icons.assignment_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 8),
                          Text(p.fullName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          if (p.isCustom) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.lavenderPurple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppRadius.small),
                              ),
                              child: Text(
                                'CUSTOM',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.lavenderPurple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          ],
                        ],
                      ),
                    )),
                const PopupMenuDivider(),
                const PopupMenuItem<int>(
                  value: -1,
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.lavenderPurple),
                      SizedBox(width: 8),
                      Text(
                        'Add Custom Exam',
                        style: TextStyle(
                          color: AppColors.lavenderPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectedPaper.isCustom ? Icons.edit_note_rounded : Icons.assignment_outlined,
                    size: 18,
                    color: AppColors.lavenderPurple,
                  ),
                  SizedBox(width: 8),
                  Text(
                    selectedPaper.fullName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => SizedBox(
        height: 38,
        width: 100,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
