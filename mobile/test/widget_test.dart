// Tennis Management App widget test.
//
// This test verifies that the Tennis Management app loads correctly
// and displays the expected initial UI components.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tennis_management/main.dart';

void main() {
  testWidgets('Tennis Management app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TennisManagementApp()));

    // Wait for the app to fully load
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // The app should be running and responsive
    expect(tester.takeException(), isNull);
  });
}
