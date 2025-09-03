import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s600/s600_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelS600 platform = MethodChannelS600();
  const MethodChannel channel = MethodChannel('s600');

  group('Method Channel Response Tests', () {
    // Create a mock handler for the method channel
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getPlatformVersion':
              return '42';
            case 'initPrinter':
              return true;
            case 'getPrinterStatus':
              return 'ready';
            case 'printText':
              return true;
            case 'printQRCode':
              return true;
            case 'printBarcode':
              return true;
            case 'printReceipt':
              return true;
            case 'feedPaper':
              return true;
            case 'setPrintDensity':
              return true;
            case 'printRawBytes':
              // Return a success response map for the printRawBytes method
              return {
                'success': true,
                'message': 'Print completed successfully'
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('getPlatformVersion', () async {
      expect(await platform.getPlatformVersion(), '42');
    });

    test('initPrinter', () async {
      expect(await platform.initPrinter(), true);
    });

    test('getPrinterStatus', () async {
      expect(await platform.getPrinterStatus(), 'ready');
    });

    test('printText', () async {
      // Test basic text printing
      expect(
        await platform.printText('Test Text', alignment: 'left', style: 'normal', fontSize: 24),
        true,
      );

      // Test with different parameters
      expect(
        await platform.printText('Test Text', alignment: 'center', style: 'bold', fontSize: 32),
        true,
      );
    });

    test('printQRCode', () async {
      // Test with default size
      expect(
        await platform.printQRCode('https://example.com'),
        true,
      );

      // Test with custom size
      expect(
        await platform.printQRCode('https://example.com', size: 300),
        true,
      );
    });

    test('printBarcode', () async {
      // Test with default parameters
      expect(
        await platform.printBarcode('123456789012'),
        true,
      );

      // Test with custom parameters
      expect(
        await platform.printBarcode('123456789012', type: 'code39', height: 120),
        true,
      );
    });

    test('feedPaper', () async {
      expect(await platform.feedPaper(3), true);
    });

    test('setPrintDensity', () async {
      expect(await platform.setPrintDensity(8), true);
    });

    // New test for printRawBytes
    test('printRawBytes', () async {
      List<int> testBytes = [27, 64, 27, 33, 0, 84, 101, 115, 116]; // ESC/POS commands for "Test"
      
      final result = await platform.printRawBytes(testBytes);
      
      // Verify the response is a Map with success and message fields
      expect(result, isA<Map>());
      expect(result['success'], true);
      expect(result['message'], 'Print completed successfully');
    });
    
    // Test with custom parameters
    test('printRawBytes with custom parameters', () async {
      List<int> testBytes = [27, 64, 27, 33, 0, 84, 101, 115, 116];
      
      final result = await platform.printRawBytes(
        testBytes,
        chunkSize: 100,
        delayMs: 200
      );
      
      expect(result['success'], true);
    });
    
    // Test method call parameters
    test('printRawBytes sends correct parameters', () async {
      final List<MethodCall> log = <MethodCall>[];
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return {'success': true, 'message': 'Print completed successfully'};
        },
      );
      
      List<int> testBytes = [27, 64, 27, 33, 0, 84, 101, 115, 116];
      await platform.printRawBytes(testBytes, chunkSize: 75, delayMs: 150);
      
      expect(log, hasLength(1));
      expect(log[0].method, 'printRawBytes');
      expect(log[0].arguments['bytes'], testBytes);
      expect(log[0].arguments['chunkSize'], 75);
      expect(log[0].arguments['delayMs'], 150);
    });
  });

  group('Method Channel Arguments Tests', () {
    final List<MethodCall> methodCalls = [];
    
    setUp(() {
      methodCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return true;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      methodCalls.clear();
    });

    test('printText arguments', () async {
      await platform.printText(
        'Hello World',
        alignment: 'center',
        style: 'bold',
        fontSize: 32,
      );
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'printText');
      expect(methodCalls[0].arguments, isA<Map>());
      
      // Access the arguments without casting
      final args = methodCalls[0].arguments;
      expect(args['text'], 'Hello World');
      expect(args['alignment'], 'center');
      expect(args['style'], 'bold');
      expect(args['fontSize'], 32);
    });

    test('printQRCode arguments', () async {
      await platform.printQRCode(
        'https://example.com',
        size: 300,
      );
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'printQRCode');
      expect(methodCalls[0].arguments, isA<Map>());
      
      // Access the arguments without casting
      final args = methodCalls[0].arguments;
      expect(args['data'], 'https://example.com');
      expect(args['size'], 300);
    });

    test('printBarcode arguments', () async {
      await platform.printBarcode(
        '123456789012',
        type: 'code39',
        height: 120,
      );
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'printBarcode');
      expect(methodCalls[0].arguments, isA<Map>());
      
      // Access the arguments without casting
      final args = methodCalls[0].arguments;
      expect(args['data'], '123456789012');
      expect(args['type'], 'code39');
      expect(args['height'], 120);
    });

    test('feedPaper arguments', () async {
      await platform.feedPaper(5);
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'feedPaper');
      expect(methodCalls[0].arguments, isA<Map>());
      
      // Access the arguments without casting
      final args = methodCalls[0].arguments;
      expect(args['lines'], 5);
    });

    test('setPrintDensity arguments', () async {
      await platform.setPrintDensity(7);
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'setPrintDensity');
      expect(methodCalls[0].arguments, isA<Map>());
      
      // Access the arguments without casting
      final args = methodCalls[0].arguments;
      expect(args['density'], 7);
    });
  });
}
