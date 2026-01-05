import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/professor/presentation/widgets/students_list_widget.dart';
import 'package:tennis_management/features/professor/presentation/providers/professor_provider.dart';
import 'package:tennis_management/features/professor/domain/models/student_summary_model.dart';

void main() {
  group('StudentsListWidget', () {
    testWidgets('should display loading state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          professorStudentsProvider.overrideWith(
            (ref) async => <StudentSummaryModel>[],
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: StudentsListWidget())),
        ),
      );

      // Pump once to see loading state
      await tester.pump();

      // Widget should be rendered
      expect(find.byType(StudentsListWidget), findsOneWidget);

      // Clean up
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      container.dispose();
    });

    testWidgets('should display empty state when no students', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          professorStudentsProvider.overrideWith(
            (ref) async => <StudentSummaryModel>[],
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: StudentsListWidget())),
        ),
      );

      await tester.pumpAndSettle();

      // Should display empty state message
      expect(find.text('No tienes estudiantes aún'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should display students list when data is available', (
      WidgetTester tester,
    ) async {
      final students = [
        StudentSummaryModel(
          id: '1',
          name: 'John Doe',
          email: 'john@example.com',
          level: 'Intermedio',
          totalClasses: 10,
          progress: 0.5,
        ),
        StudentSummaryModel(
          id: '2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          level: 'Avanzado',
          totalClasses: 20,
          progress: 0.8,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          professorStudentsProvider.overrideWith((ref) async => students),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: StudentsListWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display student names
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should display error state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          professorStudentsProvider.overrideWith((ref) async {
            throw Exception('Error loading students');
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: StudentsListWidget())),
        ),
      );

      await tester.pumpAndSettle();

      // Should display error message
      expect(
        find.textContaining('Error al cargar estudiantes'),
        findsOneWidget,
      );

      container.dispose();
    });
  });
}
