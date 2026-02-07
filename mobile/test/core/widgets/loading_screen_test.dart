import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/widgets/loading_screen.dart';

void main() {
  group('LoadingScreen', () {
    testWidgets('should display loading screen with message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: LoadingScreen(message: 'Cargando...')),
      );

      // Pump a few frames to allow animations to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cargando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up by disposing the widget tree
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'should display loading indicator when message is not provided',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(home: LoadingScreen()));

        // Pump a few frames to allow animations to start
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should display loading indicator and icon
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.sports_tennis), findsOneWidget);

        // Clean up
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('should be full screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: LoadingScreen(message: 'Loading')),
      );

      await tester.pump();

      // LoadingScreen should be a Scaffold (full screen)
      expect(find.byType(Scaffold), findsOneWidget);

      // Clean up
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}
