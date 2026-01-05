import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/home/presentation/widgets/quick_actions_grid.dart';
import 'package:tennis_management/features/auth/domain/models/user_model.dart';

void main() {
  group('QuickActionsGrid', () {
    testWidgets('should display quick actions for student', (
      WidgetTester tester,
    ) async {
      final user = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'student',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickActionsGrid(user: user)),
        ),
      );

      await tester.pumpAndSettle();

      // Should display grid
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should display quick actions for professor', (
      WidgetTester tester,
    ) async {
      final user = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'professor',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuickActionsGrid(user: user)),
        ),
      );

      await tester.pumpAndSettle();

      // Should display grid
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
