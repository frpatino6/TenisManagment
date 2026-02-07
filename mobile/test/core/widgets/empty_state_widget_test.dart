import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('should display default icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyStateWidget())),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('should display title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
      expect(find.text('There are no items to display'), findsOneWidget);
    });

    testWidgets('should display custom icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyStateWidget(icon: Icons.search_off)),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('should display action widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              action: ElevatedButton(onPressed: null, child: Text('Add Item')),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('list should use list defaults', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyStateWidget.list())),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('search should use search defaults', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyStateWidget.search())),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('schedule should use schedule defaults', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyStateWidget.schedule())),
      );

      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('booking should use booking defaults', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyStateWidget.booking())),
      );

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });
  });
}
