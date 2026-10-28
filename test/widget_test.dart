import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edumentor_ai/main.dart';
import 'package:edumentor_ai/features/auth/screens/onboarding_screen.dart';

void main() {
  group('ConfigurationErrorApp Widget Tests', () {
    testWidgets('renders configuration error message and lists missing keys without secrets', (WidgetTester tester) async {
      const missingKeys = ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY'];

      await tester.pumpWidget(
        const ConfigurationErrorApp(missingKeys: missingKeys),
      );

      // Verify the main header is present
      expect(find.text('Configuration Required'), findsOneWidget);

      // Verify explanation text is present
      expect(
        find.text('The application could not start because required configuration is missing from your .env file.'),
        findsOneWidget,
      );

      // Verify warning icon is displayed
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Verify each missing key is explicitly rendered
      expect(find.text('SUPABASE_URL'), findsOneWidget);
      expect(find.text('SUPABASE_PUBLISHABLE_KEY'), findsOneWidget);

      // Verify that no secret tokens or credential values are displayed
      expect(find.textContaining('sb_publishable_'), findsNothing);
      expect(find.textContaining('key'), findsNothing);
    });

    testWidgets('renders accurately when only a single key is missing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ConfigurationErrorApp(missingKeys: ['SUPABASE_URL']),
      );

      expect(find.text('Configuration Required'), findsOneWidget);
      expect(find.text('SUPABASE_URL'), findsOneWidget);
      expect(find.text('SUPABASE_PUBLISHABLE_KEY'), findsNothing);
    });
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders initial walkthrough slide and navigation controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      // First slide title
      expect(find.text('Learn with AI'), findsOneWidget);

      // Description text
      expect(
        find.text('Get step-by-step solutions for NEET & JEE problems anytime, anywhere.'),
        findsOneWidget,
      );

      // Navigation actions
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
