import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'screens/topic_detail_screen.dart';
import 'screens/custom_exam_form_screen.dart';
import 'screens/mock_test_screen.dart';
import 'screens/topic_notes_screen.dart';
import 'theme/app_theme.dart';

class GateTrackerApp extends StatelessWidget {
  const GateTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GATE Tracker',
      theme: AppTheme.dark,
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        if (settings.name == '/topics') {
          final subjectId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => TopicDetailScreen(subjectId: subjectId),
          );
        }
        if (settings.name == '/add-custom-exam') {
          return MaterialPageRoute(
            builder: (context) => const CustomExamFormScreen(),
          );
        }
        if (settings.name == '/mock-tests') {
          return MaterialPageRoute(
            builder: (context) => const MockTestScreen(),
          );
        }
        if (settings.name == '/topic-notes') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => TopicNotesScreen(
              topicId: args['topicId'] as int,
              topicName: args['topicName'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}
