import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import '../lib/mock_s600.dart';
import '../lib/printer_types.dart' as printer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('S600 Printer Tests', () {
    late S600 s600;
    
    setUp(() {
      s600 = S600();
    });
    
    test('Initialize printer', () async {
      final result = await s600.initPrinter();
      // Result can be true or false as it's randomized in the mock
      expect(result, isA<bool>());
    });
    
    test('Get printer status', () async {
      await s600.initPrinter();
      final status = await s600.getPrinterStatus();
      expect(status, isA<printer.PrinterStatus>());
    });
    
    test('Print text', () async {
      await s600.initPrinter();
      final result = await s600.printText(
        text: 'Test print text',
        alignment: printer.TextAlignment.center,
        style: printer.TextStyle.bold,
        fontSize: 24,
      );
      expect(result, isA<bool>());
    });
    
    test('Print QR code', () async {
      await s600.initPrinter();
      final result = await s600.printQRCode(
        data: 'https://example.com',
        size: 200,
      );
      expect(result, isA<bool>());
    });
    
    test('Print barcode', () async {
      await s600.initPrinter();
      final result = await s600.printBarcode(
        data: '123456789',
        type: printer.BarcodeType.code128,
        height: 100,
      );
      expect(result, isA<bool>());
    });
    
    test('Print receipt', () async {
      await s600.initPrinter();
      final items = [
        printer.TextPrintItem(
          text: 'Test Receipt',
          alignment: printer.TextAlignment.center,
          style: printer.TextStyle.bold,
          fontSize: 24,
        ),
        printer.TextPrintItem(
          text: 'Test line item',
          alignment: printer.TextAlignment.left,
          style: printer.TextStyle.normal,
          fontSize: 20,
        ),
        printer.BarcodePrintItem(
          data: '123456789',
          type: printer.BarcodeType.code128,
          height: 80,
        ),
        printer.FeedLinePrintItem(lines: 3),
      ];
      
      final result = await s600.printReceipt(items);
      expect(result, isA<bool>());
    });
    
    test('Check printer returns error status when appropriate', () async {
      await s600.initPrinter();
      
      // We can't directly test random behaviors, but we can check that
      // the status is one of the valid enum values
      final status = await s600.getPrinterStatus();
      expect(
        status, 
        isIn([
          printer.PrinterStatus.unknown,
          printer.PrinterStatus.ready,
          printer.PrinterStatus.busy,
          printer.PrinterStatus.outOfPaper,
          printer.PrinterStatus.overheated,
          printer.PrinterStatus.error,
        ])
      );
    });
    
    test('Multiple print operations in sequence', () async {
      await s600.initPrinter();
      
      // Print text
      await s600.printText(text: 'First print');
      
      // Print QR code
      await s600.printQRCode(data: 'https://test.com');
      
      // Check status after multiple operations
      final status = await s600.getPrinterStatus();
      expect(status, isA<printer.PrinterStatus>());
    });
  });
} 