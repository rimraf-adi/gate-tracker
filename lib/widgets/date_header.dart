import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHeader extends StatelessWidget {
  const DateHeader({super.key});

  String get _day => DateFormat('dd').format(DateTime.now());
  String get _month => DateFormat('MMMM').format(DateTime.now());
  String get _weekday => DateFormat('EEEE').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_day, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_month, style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.1)),
                Text(_weekday, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
