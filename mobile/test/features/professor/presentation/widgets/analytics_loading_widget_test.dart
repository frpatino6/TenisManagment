import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/professor/presentation/widgets/analytics_loading_widget.dart';

void main() {
  group('AnalyticsLoadingWidget', () {
    testWidgets('should display analytics loading widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsLoadingWidget(),
          ),
        ),
      );

      await tester.pump();

      // Widget should be rendered
      expect(find.byType(AnalyticsLoadingWidget), findsOneWidget);
      
      // Clean up
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('should display with custom title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsLoadingWidget(
              title: 'Cargando análisis',
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Cargando análisis'), findsOneWidget);
      
      // Clean up
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('should display with subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsLoadingWidget(
              title: 'Cargando',
              subtitle: 'Por favor espera...',
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Por favor espera...'), findsOneWidget);
      
      // Clean up
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}

