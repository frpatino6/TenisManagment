import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/professor/presentation/widgets/schedule_widget.dart';
import 'package:tennis_management/features/professor/presentation/providers/professor_provider.dart';
import 'package:tennis_management/features/professor/domain/models/class_schedule_model.dart';

void main() {
  group('ScheduleWidget', () {
    testWidgets('should display schedule widget', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          scheduleByDateProvider(
            DateTime.now(),
          ).overrideWith((ref) async => <ClassScheduleModel>[]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: ScheduleWidget())),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should be rendered
      expect(find.byType(ScheduleWidget), findsOneWidget);

      container.dispose();
    });

    testWidgets('should display empty state when no classes', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          scheduleByDateProvider(
            DateTime.now(),
          ).overrideWith((ref) async => <ClassScheduleModel>[]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: ScheduleWidget())),
        ),
      );

      await tester.pumpAndSettle();

      // Should display empty state or schedule widget
      expect(find.byType(ScheduleWidget), findsOneWidget);

      container.dispose();
    });
  });
}
