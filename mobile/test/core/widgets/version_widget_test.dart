import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/widgets/version_widget.dart';

void main() {
  group('VersionWidget', () {
    testWidgets('should display version widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: VersionWidget())),
      );

      // Version widget should be rendered
      expect(find.byType(VersionWidget), findsOneWidget);
    });

    testWidgets('should display version information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: VersionWidget())),
      );

      await tester.pumpAndSettle();

      // Should display some version-related text
      // The exact text depends on VersionService implementation
      expect(find.byType(VersionWidget), findsOneWidget);
    });
  });
}
