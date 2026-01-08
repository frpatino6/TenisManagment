import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/main_common.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tennis_management/core/config/firebase_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Class Booking Integration Test', () {
    testWidgets('Full Class Booking Flow - Student Happy Path', (
      WidgetTester tester,
    ) async {
      // Initialize Firebase safely
      try {
        await Firebase.initializeApp(
          options: FirebaseConfig.developmentOptions,
        );
      } catch (_) {
        // Ignore duplicate app initialization
      }

      // 1. Launch App
      await tester.pumpWidget(
        const ProviderScope(child: TennisManagementApp()),
      );
      await tester.pumpAndSettle();

      // 2. Login
      // Verify we are at login screen
      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.text('Inicia sesión en tu cuenta'), findsOneWidget);

      final emailInput = find.byType(TextFormField).at(0);
      final passwordInput = find.byType(TextFormField).at(1);

      await tester.enterText(emailInput, 'cliente1@gmail.com');
      await tester.enterText(passwordInput, 's4ntiago');
      await tester.pumpAndSettle();

      // Find Login Button
      final loginButton = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');

      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(
        const Duration(seconds: 2),
      ); // Wait for login logic to complete

      // 3. Select Tenant (If prompted)
      if (find.text('Seleccionar Centro').evaluate().isNotEmpty) {
        print('DEBUG: At Tenant Selection Screen');
        await tester.pumpAndSettle();

        // Tap the first available tenant in the list
        final tenantCard = find.byType(Card).first;
        await tester.tap(tenantCard);
        await tester.pumpAndSettle();
      }

      // 4. Navigate to Class Booking
      // On HomeScreen, look for 'Reservar Clase' card
      final bookClassButton = find.text('Reservar Clase');

      // Scroll until visible if needed
      await tester.scrollUntilVisible(
        bookClassButton,
        500.0,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(bookClassButton);
      await tester.pumpAndSettle();

      // 5. Select Professor
      expect(find.text('Reservar Clase'), findsOneWidget);
      expect(find.text('Selecciona un profesor'), findsOneWidget);

      // Wait for professors to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 6. Select Professor and Schedule
      // We will iterate through the first few professors to find one with available schedules.

      final professorCardsFinder = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Card),
      );

      // Wait for at least one card
      await tester.pumpAndSettle();

      final int professorCount = professorCardsFinder.evaluate().length;
      print('DEBUG: Found $professorCount professors');

      bool bookingInitiated = false;

      // Try up to 3 professors
      for (int i = 0; i < professorCount && i < 3; i++) {
        print('DEBUG: Checking professor index $i');
        final card = professorCardsFinder.at(i);

        // Ensure card is visible and tap
        await tester.scrollUntilVisible(
          card,
          500.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(card);
        await tester.pumpAndSettle();

        // Check availability of "Reservar" buttons
        final bookButtonFinder = find.text('Reservar');
        if (bookButtonFinder.evaluate().isNotEmpty) {
          print('DEBUG: Found schedules for professor $i');

          // Scroll to the first 'Reservar' button
          await tester.scrollUntilVisible(
            bookButtonFinder.first,
            500.0,
            scrollable: find.byType(Scrollable).first,
          );

          await tester.tap(bookButtonFinder.first);
          await tester.pumpAndSettle();
          bookingInitiated = true;
          break;
        } else {
          print('DEBUG: No schedules for professor $i');
          // Continue to next
        }
      }

      if (!bookingInitiated) {
        // Fail the test if we couldn't perform the happy path
        fail(
          'TEST FAILURE: Could not find any professor with available schedules among the first 3 checked. Cannot verify booking flow.',
        );
      }

      // 8. Verify Success
      expect(find.textContaining('exitosamente'), findsOneWidget);
    });
  });
}
