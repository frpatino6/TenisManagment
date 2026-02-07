import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/widgets/error_widget.dart';
import 'package:tennis_management/core/exceptions/exceptions.dart';

void main() {
  group('AppErrorWidget', () {
    testWidgets('should display error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppErrorWidget(message: 'Error message')),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('should display custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(message: 'Error', icon: Icons.warning),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should display retry button when onRetry is provided', (
      tester,
    ) async {
      var retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Error message',
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Tap on the text to trigger the button
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(retryCalled, isTrue);
    });

    testWidgets('fromException should display exception message', (
      tester,
    ) async {
      final exception = AuthException.notAuthenticated();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppErrorWidget.fromException(exception)),
        ),
      );

      expect(find.text(exception.message), findsOneWidget);
    });

    testWidgets('fromError should display error message', (tester) async {
      final error = Exception('Generic error');
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppErrorWidget.fromError(error))),
      );

      expect(find.textContaining('Generic error'), findsOneWidget);
    });

    testWidgets('fromError should use custom message when provided', (
      tester,
    ) async {
      final error = Exception('Generic error');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.fromError(
              error,
              message: 'Custom error message',
            ),
          ),
        ),
      );

      expect(find.text('Custom error message'), findsOneWidget);
    });
  });
}
