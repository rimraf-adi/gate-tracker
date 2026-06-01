import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gate_tracker/app.dart';
import 'package:gate_tracker/services/preferences_service.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App launch and smoke test', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(PreferencesService(prefs)),
        ],
        child: const GateTrackerApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
