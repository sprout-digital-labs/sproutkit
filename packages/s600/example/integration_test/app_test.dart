import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:s600_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Printer UI Tests', () {
    testWidgets('App initializes and shows all UI elements', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app title is displayed
      expect(find.text('S600 Printer Example'), findsOneWidget);

      // Verify status panel is displayed
      expect(find.text('Initialization:'), findsOneWidget);
      expect(find.text('Printer Status:'), findsOneWidget);

      // Verify all buttons are displayed
      expect(find.text('Initialize Printer'), findsOneWidget);
      expect(find.text('Check Printer Status'), findsOneWidget);
      expect(find.text('Print Sample Text'), findsOneWidget);
      expect(find.text('Print QR Code'), findsOneWidget);
      expect(find.text('Print Sample Receipt'), findsOneWidget);
    });

    testWidgets('Test printer initialization flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap the initialize button
      await tester.tap(find.text('Initialize Printer'));
      
      // Wait for the initialization to complete (mock has 1 second delay)
      await tester.pump(const Duration(milliseconds: 1200));
      
      // Status should have changed
      expect(
        find.textContaining('initialized'), 
        findsOneWidget
      );
    });

    testWidgets('Test check status button', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First initialize the printer
      await tester.tap(find.text('Initialize Printer'));
      await tester.pump(const Duration(milliseconds: 1200));

      // Tap the check status button
      await tester.tap(find.text('Check Printer Status'));
      
      // Wait for the status check to complete
      await tester.pump(const Duration(milliseconds: 600));
      
      // Status text should have been updated
      expect(
        find.textContaining('Printer status'), 
        findsOneWidget
      );
    });

    testWidgets('Test print text button', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First initialize the printer
      await tester.tap(find.text('Initialize Printer'));
      await tester.pump(const Duration(milliseconds: 1200));

      // Tap the print text button
      await tester.tap(find.text('Print Sample Text'));
      
      // Wait for the printing to complete
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should show "Printing sample text..."
      expect(
        find.text('Printing sample text...'), 
        findsOneWidget
      );
      
      // Wait for the printing to complete
      await tester.pump(const Duration(milliseconds: 1500));
      
      // Status should have been updated with the result
      expect(
        find.textContaining('text printed'), 
        findsAtLeastNWidgets(1)
      );
    });

    testWidgets('Test print QR code button', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First initialize the printer
      await tester.tap(find.text('Initialize Printer'));
      await tester.pump(const Duration(milliseconds: 1200));

      // Tap the print QR code button
      await tester.tap(find.text('Print QR Code'));
      
      // Wait for the printing to start
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should show "Printing QR code..."
      expect(
        find.text('Printing QR code...'), 
        findsOneWidget
      );
      
      // Wait for the printing to complete
      await tester.pump(const Duration(milliseconds: 2000));
      
      // Status should have been updated with the result
      expect(
        find.textContaining('QR code printed'), 
        findsAtLeastNWidgets(1)
      );
    });

    testWidgets('Test print receipt button', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First initialize the printer
      await tester.tap(find.text('Initialize Printer'));
      await tester.pump(const Duration(milliseconds: 1200));

      // Tap the print receipt button
      await tester.tap(find.text('Print Sample Receipt'));
      
      // Wait for the printing to start
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should show "Printing receipt..."
      expect(
        find.text('Printing receipt...'), 
        findsOneWidget
      );
      
      // Wait for the printing to complete (sample receipt has 9 items)
      await tester.pump(const Duration(milliseconds: 3500));
      
      // Status should have been updated with the result
      expect(
        find.textContaining('Receipt printed'), 
        findsAtLeastNWidgets(1)
      );
    });
  });
} 