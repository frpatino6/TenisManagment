import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/main_common.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tennis_management/core/config/firebase_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loginAsStudent(WidgetTester tester) async {
    // Initialize Firebase safely
    try {
      await Firebase.initializeApp(options: FirebaseConfig.developmentOptions);
    } catch (_) {
      // Ignore duplicate app initialization
    }

    // 1. Launch App
    await tester.pumpWidget(const ProviderScope(child: TennisManagementApp()));
    await tester.pumpAndSettle();

    // 2. Login
    // Verify we are at login screen
    if (find.text('Inicia sesión en tu cuenta').evaluate().isNotEmpty) {
      final emailInput = find.byType(TextFormField).at(0);
      final passwordInput = find.byType(TextFormField).at(1);

      await tester.enterText(emailInput, 'cliente1@gmail.com');
      await tester.enterText(passwordInput, 's4ntiago');
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
  }

  group('Booking Flow Integration Test', () {
    testWidgets('Full Booking Flow - Student Happy Path', (
      WidgetTester tester,
    ) async {
      await loginAsStudent(tester);

      // 3. Select Tenant (If prompted)
      if (find.text('Seleccionar Centro').evaluate().isNotEmpty) {
        await tester.pumpAndSettle();
        final tenantCard = find.byType(Card).first;
        await tester.tap(tenantCard);
        await tester.pumpAndSettle();
      }

      // 4. Navigate to Booking
      final bookingButton = find.text('Reservar Cancha');
      await tester.scrollUntilVisible(
        bookingButton,
        500.0,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(bookingButton);
      await tester.pumpAndSettle();

      // 5. Select Court
      expect(find.text('Reservar Cancha'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.sports_tennis).first);
      await tester.pumpAndSettle();

      // 6. Select Date
      await tester.tap(find.text('Selecciona una fecha'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      // 7. Select Time
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final stringTimeChips = find.byType(FilterChip);

      if (stringTimeChips.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          stringTimeChips.first,
          100.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(stringTimeChips.first);
        await tester.pumpAndSettle();
      } else {
        return;
      }

      // 8. Confirm
      final confirmBtn = find.text('Confirmar Reserva');
      await tester.scrollUntilVisible(
        confirmBtn,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // 9. Verify Success
      expect(find.textContaining('exitosamente'), findsOneWidget);
    });

    testWidgets('Change Tenant Flow', (WidgetTester tester) async {
      await loginAsStudent(tester);

      // Navigate to "Reservar Cancha" where the dropdown is located
      final bookingButton = find.text('Reservar Cancha');
      await tester.scrollUntilVisible(
        bookingButton,
        500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(bookingButton);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check if we are in "Selecciona un centro" state or if we have a dropdown
      // The implementation of BookCourtScreen shows a dropdown if tenants are loaded
      // We look for DropdownButtonFormField<String>
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);

      if (dropdownFinder.evaluate().isNotEmpty) {
        // Tap to open
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        // Select the second item (assuming there is more than 1)
        // If there is only 1, this might fail or just re-select the same.
        // We'll try to find DropdownMenuItem
        final menuItems = find.byType(DropdownMenuItem<String>);
        if (menuItems.evaluate().length > 1) {
          final secondItem = menuItems.at(1);
          await tester.tap(secondItem);
          await tester.pumpAndSettle();

          // Verify snackbar
          expect(find.textContaining('Centro cambiado a'), findsOneWidget);

          // Wait for courts to reload for the new tenant
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Now proceed with Booking for the new tenant

          // 1. Select First Available Court
          // Note: ID might have changed, so we find by Icon again
          final courtIcons = find.byIcon(Icons.sports_tennis);
          if (courtIcons.evaluate().isNotEmpty) {
            await tester.tap(courtIcons.first);
            await tester.pumpAndSettle();

            // 2. Select Date
            await tester.tap(find.text('Selecciona una fecha'));
            await tester.pumpAndSettle();
            await tester.tap(
              find.byType(TextButton).last,
            ); // Confirm DatePicker
            await tester.pumpAndSettle();

            // 3. Select Time
            await tester.pumpAndSettle(const Duration(seconds: 1));
            final stringTimeChips = find.byType(FilterChip);

            if (stringTimeChips.evaluate().isNotEmpty) {
              await tester.scrollUntilVisible(
                stringTimeChips.first,
                100.0,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.tap(stringTimeChips.first);
              await tester.pumpAndSettle();

              // 4. Confirm
              final confirmBtn = find.text('Confirmar Reserva');
              await tester.scrollUntilVisible(
                confirmBtn,
                100.0,
                scrollable: find.byType(Scrollable).first,
              );

              await tester.tap(confirmBtn);
              await tester.pumpAndSettle();

              // 5. Verify Success
              expect(find.textContaining('exitosamente'), findsOneWidget);
            }
          }
        } else {
          // Click the first one to close it or verify content
          if (menuItems.evaluate().isNotEmpty) {
            await tester.tap(menuItems.first);
            await tester.pumpAndSettle();
          }
        }
      }
    });
  });
}
