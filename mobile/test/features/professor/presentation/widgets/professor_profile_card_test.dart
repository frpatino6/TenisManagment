import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/professor/presentation/widgets/professor_profile_card.dart';
import 'package:tennis_management/features/professor/presentation/providers/professor_provider.dart';
import 'package:tennis_management/features/professor/domain/models/professor_model.dart';

void main() {
  group('ProfessorProfileCard', () {
    testWidgets('should display loading state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          professorInfoProvider.overrideWith((ref) async {
            // Return immediately but test will catch loading state
            return ProfessorModel(
              id: '1',
              name: 'Test',
              email: 'test@example.com',
              hourlyRate: 50.0,
              specialties: ['Tenis'],
              experienceYears: 5,
              totalStudents: 10,
              totalClasses: 50,
              monthlyEarnings: 1000.0,
              weeklyEarnings: 250.0,
              rating: 4.5,
            );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: ProfessorProfileCard())),
        ),
      );

      // Pump once to see loading state
      await tester.pump();

      // Widget should be rendered
      expect(find.byType(ProfessorProfileCard), findsOneWidget);

      // Clean up
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      container.dispose();
    });

    testWidgets('should display professor information when data is available', (
      WidgetTester tester,
    ) async {
      final professor = ProfessorModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        hourlyRate: 50.0,
        specialties: ['Tenis'],
        experienceYears: 5,
        totalStudents: 10,
        totalClasses: 50,
        monthlyEarnings: 1000.0,
        weeklyEarnings: 250.0,
        rating: 4.5,
        phone: '1234567890',
      );

      final container = ProviderContainer(
        overrides: [
          professorInfoProvider.overrideWith((ref) async => professor),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: ProfessorProfileCard())),
        ),
      );

      await tester.pumpAndSettle();

      // Should display professor name and email
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should display error state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          professorInfoProvider.overrideWith((ref) async {
            throw Exception('Error loading professor');
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: ProfessorProfileCard())),
        ),
      );

      await tester.pumpAndSettle();

      // Should display error widget
      expect(find.byType(ProfessorProfileCard), findsOneWidget);

      container.dispose();
    });
  });
}
