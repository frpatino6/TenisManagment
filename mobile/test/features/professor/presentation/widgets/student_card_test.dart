import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/professor/presentation/widgets/student_card.dart';
import 'package:tennis_management/features/professor/domain/models/student_model.dart';

void main() {
  group('StudentCard', () {
    testWidgets('should display student information', (
      WidgetTester tester,
    ) async {
      final student = StudentModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        membershipType: MembershipType.basic,
        balance: 100.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StudentCard(student: student)),
        ),
      );

      await tester.pumpAndSettle();

      // Should display student name
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;
      final student = StudentModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        membershipType: MembershipType.basic,
        balance: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentCard(
              student: student,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the card
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should display student initials', (WidgetTester tester) async {
      final student = StudentModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        membershipType: MembershipType.basic,
        balance: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StudentCard(student: student)),
        ),
      );

      await tester.pumpAndSettle();

      // Should display initials (JD for John Doe)
      expect(find.text('JD'), findsOneWidget);
    });
  });
}
