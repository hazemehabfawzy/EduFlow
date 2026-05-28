import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduflow/widgets/gradient_button.dart';

void main() {
  group('GradientButton Widget Tests', () {
    testWidgets('renders button with label and icon', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              label: 'Submit Course',
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      // Verify button label is rendered
      expect(find.text('Submit Course'), findsOneWidget);

      // Verify icon is rendered
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Tap the button and verify onPressed is called
      await tester.tap(find.text('Submit Course'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('renders loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GradientButton(
              label: 'Submit Course',
              isLoading: true,
            ),
          ),
        ),
      );

      // Verify button label is not visible/rendered
      expect(find.text('Submit Course'), findsNothing);

      // Verify circular progress indicator is rendered
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

