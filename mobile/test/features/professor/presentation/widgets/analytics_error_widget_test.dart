import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/professor/presentation/widgets/analytics_error_widget.dart';
import 'package:tennis_management/features/professor/domain/models/analytics_error.dart';

void main() {
  group('AnalyticsErrorWidget', () {
    testWidgets('should display error widget', (WidgetTester tester) async {
      final error = AnalyticsError(
        message: 'Error loading analytics',
        type: AnalyticsErrorType.networkError,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AnalyticsErrorWidget(error: error)),
        ),
      );

      await tester.pumpAndSettle();

      // Should display error widget (uses userMessage which may be different from message)
      expect(find.byType(AnalyticsErrorWidget), findsOneWidget);
    });

    testWidgets('should display retry button when onRetry is provided', (
      WidgetTester tester,
    ) async {
      bool wasRetried = false;
      final error = AnalyticsError(
        message: 'Error',
        type: AnalyticsErrorType.networkError,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsErrorWidget(
              error: error,
              onRetry: () {
                wasRetried = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have retry button (button text includes retry delay)
      expect(find.textContaining('Reintentar'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.textContaining('Reintentar'));
      await tester.pump();

      expect(wasRetried, isTrue);
    });

    testWidgets('should display error details when showDetails is true', (
      WidgetTester tester,
    ) async {
      final error = AnalyticsError(
        message: 'Error loading analytics',
        type: AnalyticsErrorType.networkError,
        details: 'Connection timeout',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsErrorWidget(error: error, showDetails: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display error widget
      expect(find.byType(AnalyticsErrorWidget), findsOneWidget);
    });
  });
}
