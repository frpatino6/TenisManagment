import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/auth/presentation/widgets/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('should display button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Login'));
      expect(wasPressed, isTrue);
    });

    testWidgets('should be disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should display loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    });

    testWidgets('should be disabled when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should display icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              icon: Icons.login,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should use outlined style when isOutlined is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              isOutlined: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('should respect custom width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              width: 200,
              onPressed: () {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, equals(200));
    });

    testWidgets('should respect custom height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Login',
              height: 60,
              onPressed: () {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, equals(60));
    });
  });

  group('CustomIconButton', () {
    testWidgets('should display icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.settings,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.settings,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      expect(wasPressed, isTrue);
    });

    testWidgets('should display tooltip when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconButton(
              icon: Icons.settings,
              tooltip: 'Settings',
              onPressed: () {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Settings'));
    });
  });

  group('CustomFloatingActionButton', () {
    testWidgets('should display icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomFloatingActionButton(
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomFloatingActionButton(
              icon: Icons.add,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      expect(wasPressed, isTrue);
    });

    testWidgets('should display tooltip when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomFloatingActionButton(
              icon: Icons.add,
              tooltip: 'Add',
              onPressed: () {},
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.tooltip, equals('Add'));
    });
  });
}

