import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gate_tracker/app.dart';

void main() {
  setUpAll(() {
    // Initialize sqflite_common_ffi for testing on host machines
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App launch and smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: GateTrackerApp(),
      ),
    );

    // Verify that the app title or key widgets render (e.g. CircularProgressIndicator while loading)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
