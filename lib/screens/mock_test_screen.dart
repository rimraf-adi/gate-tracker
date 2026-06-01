import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/glass_card.dart';
import '../models/mock_test.dart';
import '../services/database_helper.dart';

class MockTestScreen extends ConsumerWidget {
  const MockTestScreen({super.key});

  void _showAddTestSheet(BuildContext context, int paperId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => _AddTestForm(paperId: paperId),
    );
  }

  Future<bool?> _showConfirmDeleteDialog(BuildContext context, String testName) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text('Delete Mock Test?'),
        content: Text('Are you sure you want to delete the records for "$testName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperId = ref.watch(selectedPaperIdProvider);
    final testsAsync = ref.watch(mockTestsByPaperProvider(paperId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mock Tests',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded),
            color: AppColors.lavenderPurple,
            iconSize: 32,
            onPressed: () => _showAddTestSheet(context, paperId),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Expanded(
              child: testsAsync.when(
                data: (tests) {
                  if (tests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, size: 64, color: Colors.white54),
                          SizedBox(height: 12),
                          Text(
                            'No mock tests added yet.',
                            style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tap the + button to add your first test!',
                            style: TextStyle(fontSize: 14, color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      final test = tests[index];
                      return Dismissible(
                        key: Key(test.id.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) => _showConfirmDeleteDialog(context, test.testName),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: Colors.redAccent.withValues(alpha: 0.9),
                          child: Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) async {
                          final db = DatabaseHelper.instance;
                          await db.deleteMockTest(test.id!);
                          ref.invalidate(mockTestsByPaperProvider(paperId));
                          ref.invalidate(totalMockTestsCountProvider(paperId));
                          ref.invalidate(averageMockScoreProvider(paperId));

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted "${test.testName}"'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  textColor: AppColors.limeGreen,
                                  onPressed: () async {
                                    await db.addMockTest(test);
                                    ref.invalidate(mockTestsByPaperProvider(paperId));
                                    ref.invalidate(totalMockTestsCountProvider(paperId));
                                    ref.invalidate(averageMockScoreProvider(paperId));
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: _testCard(context, test),
                      );
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testCard(BuildContext context, MockTest test) {
    final percentage = test.totalMarks > 0 ? test.marksObtained / test.totalMarks : 0.0;
    final dateFormatted = DateFormat('MMMM dd, yyyy').format(test.date);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  test.testName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                ),
              ),
              Text(
                dateFormatted,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${test.marksObtained}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      color: Theme.of(context).colorScheme.surface,
                    ),
              ),
              Text(
                ' / ${test.totalMarks}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppColors.lavenderPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: const AlwaysStoppedAnimation(AppColors.lavenderPurple),
            ),
          ),
          if (test.percentile != null || test.rank != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                if (test.percentile != null) ...[
                  Icon(Icons.percent_rounded, size: 16, color: Colors.white70),
                  SizedBox(width: 4),
                  Text(
                    'Percentile: ${test.percentile!.toStringAsFixed(1)}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  SizedBox(width: 20),
                ],
                if (test.rank != null) ...[
                  Icon(Icons.emoji_events_rounded, size: 16, color: Colors.orangeAccent),
                  SizedBox(width: 4),
                  Text(
                    'Rank: #${test.rank}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ],
            )
          ],
        ],
      ),
    );
  }
}

class _AddTestForm extends ConsumerStatefulWidget {
  final int paperId;

  const _AddTestForm({required this.paperId});

  @override
  ConsumerState<_AddTestForm> createState() => _AddTestFormState();
}

class _AddTestFormState extends ConsumerState<_AddTestForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalController = TextEditingController();
  final _obtainedController = TextEditingController();
  final _percentileController = TextEditingController();
  final _rankController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Mock Test',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Test Name (e.g. GATE 2025 CSE)',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter test name' : null,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _obtainedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Marks Obtained',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final numVal = int.tryParse(val);
                        if (numVal == null) return 'Must be number';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Marks',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final numVal = int.tryParse(val);
                        if (numVal == null) return 'Must be number';
                        final obtained = int.tryParse(_obtainedController.text);
                        if (obtained != null && numVal < obtained) {
                          return 'Cannot be < Obtained';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _percentileController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Percentile (Optional)',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rankController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Rank (Optional)',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Test Date: ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _selectDate,
                    icon: Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.lavenderPurple),
                    label: Text('Change', style: TextStyle(color: AppColors.lavenderPurple, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lavenderPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final obtained = int.parse(_obtainedController.text);
                          final total = int.parse(_totalController.text);
                          final percentile = double.tryParse(_percentileController.text);
                          final rank = int.tryParse(_rankController.text);

                          final mockTest = MockTest(
                            paperId: widget.paperId,
                            testName: _nameController.text.trim(),
                            date: _selectedDate,
                            totalMarks: total,
                            marksObtained: obtained,
                            percentile: percentile,
                            rank: rank,
                          );

                          await DatabaseHelper.instance.addMockTest(mockTest);
                          ref.invalidate(mockTestsByPaperProvider(widget.paperId));
                          ref.invalidate(totalMockTestsCountProvider(widget.paperId));
                          ref.invalidate(averageMockScoreProvider(widget.paperId));

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mock test result saved!')),
                            );
                          }
                        }
                      },
                      child: Text('Save Test', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
