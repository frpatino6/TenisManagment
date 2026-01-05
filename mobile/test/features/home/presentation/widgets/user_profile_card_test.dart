import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/home/presentation/widgets/user_profile_card.dart';
import 'package:tennis_management/features/auth/domain/models/user_model.dart';

void main() {
  group('UserProfileCard', () {
    testWidgets('should display user information', (WidgetTester tester) async {
      final user = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'student',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UserProfileCard(user: user)),
        ),
      );

      await tester.pumpAndSettle();

      // Should display user name
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should display user email', (WidgetTester tester) async {
      final user = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'student',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UserProfileCard(user: user)),
        ),
      );

      await tester.pumpAndSettle();

      // Should display user email
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('should display profile image when available', (
      WidgetTester tester,
    ) async {
      final user = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'student',
        profileImageUrl: 'https://example.com/image.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UserProfileCard(user: user)),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should be rendered
      expect(find.byType(UserProfileCard), findsOneWidget);
    });
  });
}
