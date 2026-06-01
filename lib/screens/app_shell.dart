import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'subject_list_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import '../widgets/floating_bottom_nav.dart';
import '../theme/app_background.dart';
import '../services/syllabus_loader.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _loading = true;

  final _screens = const [
    CalendarScreen(),
    SubjectListScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initSyllabi();
  }

  Future<void> _initSyllabi() async {
    await SyllabusLoader.instance.loadAllIfNeeded();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}
