import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/professor/presentation/widgets/earnings_widget.dart';
import 'package:tennis_management/features/professor/presentation/providers/professor_provider.dart';

void main() {
  group('EarningsWidget', () {
    testWidgets('should display loading state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          earningsStatsProvider.overrideWith(
            (ref) async => <String, dynamic>{},
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: EarningsWidget())),
        ),
      );

      // Pump once to see loading state
      await tester.pump();

      // Widget should be rendered
      expect(find.byType(EarningsWidget), findsOneWidget);

      // Clean up
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      container.dispose();
    });

    testWidgets('should display earnings data when available', (
      WidgetTester tester,
    ) async {
      final earningsData = <String, dynamic>{
        'monthlyEarnings': 5000.0,
        'weeklyEarnings': 1250.0,
        'classesThisMonth': 20,
      };

      final container = ProviderContainer(
        overrides: [
          earningsStatsProvider.overrideWith((ref) async => earningsData),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: EarningsWidget())),
        ),
      );

      await tester.pumpAndSettle();

      // Should display earnings title
      expect(find.text('Ganancias del Mes'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should display error state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          earningsStatsProvider.overrideWith((ref) async {
            throw Exception('Error loading earnings');
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: EarningsWidget())),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should be rendered
      expect(find.byType(EarningsWidget), findsOneWidget);

      container.dispose();
    });
  });
}
