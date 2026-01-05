import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/professor/presentation/widgets/tenant_selector_widget.dart';

void main() {
  group('TenantSelectorWidget', () {
    testWidgets('should display tenant selector widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TenantSelectorWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TenantSelectorWidget), findsOneWidget);
    });

    testWidgets('should display when no tenant is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TenantSelectorWidget(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should be visible even when no tenant is selected
      expect(find.byType(TenantSelectorWidget), findsOneWidget);
    });
  });
}

