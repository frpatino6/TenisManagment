import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/professor/presentation/widgets/tenant_selector_widget.dart';
import 'package:tennis_management/core/providers/tenant_provider.dart';
import 'package:tennis_management/features/tenant/domain/models/tenant_model.dart';
import 'package:tennis_management/features/tenant/domain/services/tenant_service.dart'
    as tenant_domain;

void main() {
  group('TenantSelectorWidget', () {
    testWidgets('should display tenant selector widget', (
      WidgetTester tester,
    ) async {
      final testTenant = TenantModel(
        id: 'tenant-1',
        name: 'Test Center',
        slug: 'test-center',
        isActive: true,
      );

      final container = ProviderContainer(
        overrides: [
          // Override professorTenantsProvider directly instead of the service
          professorTenantsProvider.overrideWith((ref) async => [testTenant]),
          currentTenantProvider.overrideWith((ref) async => testTenant),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 800,
                  height: 2000,
                  child: TenantSelectorWidget(),
                ),
              ),
            ),
          ),
        ),
      );

      // Pump multiple times to handle async providers and animations
      await tester.pump();
      await tester.pump();

      expect(find.byType(TenantSelectorWidget), findsOneWidget);

      // Wait for animations to complete before cleanup
      await tester.pump(const Duration(seconds: 2));

      // Clean up
      await tester.pumpWidget(Container());
      container.dispose();
    });

    testWidgets('should display when no tenant is selected', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          // Override professorTenantsProvider directly instead of the service
          professorTenantsProvider.overrideWith((ref) async => <TenantModel>[]),
          currentTenantProvider.overrideWith((ref) async => null),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 800,
                  height: 2000,
                  child: TenantSelectorWidget(),
                ),
              ),
            ),
          ),
        ),
      );

      // Pump multiple times to handle async providers
      await tester.pump();
      await tester.pump();

      // Widget should be visible even when no tenant is selected
      expect(find.byType(TenantSelectorWidget), findsOneWidget);

      // Wait for animations to complete before cleanup
      await tester.pump(const Duration(seconds: 2));

      // Clean up
      await tester.pumpWidget(Container());
      container.dispose();
    });
  });
}
