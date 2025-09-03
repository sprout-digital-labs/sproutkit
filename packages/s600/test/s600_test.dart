import 'package:flutter_test/flutter_test.dart';
import 'package:s600/s600.dart';
import 'package:s600/s600_platform_interface.dart';
import 'package:s600/s600_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockS600Platform
    with MockPlatformInterfaceMixin
    implements S600Platform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  
  @override
  Future<bool> initPrinter() => Future.value(true);
  
  @override
  Future<String> getPrinterStatus() => Future.value('ready');
  
  @override
  Future<bool> printText(String text, {String alignment = 'left', String style = 'normal', int fontSize = 24}) => 
      Future.value(true);
      
  @override
  Future<bool> printQRCode(String data, {int size = 200}) => Future.value(true);
  
  @override
  Future<bool> printBarcode(String data, {String type = 'code128', int height = 100}) => 
      Future.value(true);
      
  @override
  Future<bool> feedPaper(int lines) => Future.value(true);
  
  @override
  Future<bool> setPrintDensity(int density) => Future.value(true);
  
  @override
  Future<dynamic> printRawBytes(List<int> bytes, {int chunkSize = 50, int delayMs = 50}) {
    // Return a success response map to simulate the actual implementation
    return Future.value({
      'success': true,
      'message': 'Print completed successfully'
    });
  }
}

void main() {
  final S600Platform initialPlatform = S600Platform.instance;

  test('$MethodChannelS600 is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelS600>());
  });

  group('S600 Plugin Tests', () {
    late S600 s600Plugin;
    late MockS600Platform fakePlatform;
    
    setUp(() {
      s600Plugin = S600();
      fakePlatform = MockS600Platform();
      S600Platform.instance = fakePlatform;
    });
    
    test('getPlatformVersion', () async {
      expect(await s600Plugin.getPlatformVersion(), '42');
    });
    
    test('initPrinter', () async {
      final result = await s600Plugin.initPrinter();
      expect(result, true);
    });
    
    test('getPrinterStatus', () async {
      final result = await s600Plugin.getPrinterStatus();
      expect(result, 'ready');
    });
    
    test('printText', () async {
      // Test with default parameters
      var result = await s600Plugin.printText(
        text: 'Test Text',
      );
      expect(result, true);
      
      // Test with custom parameters
      result = await s600Plugin.printText(
        text: 'Test Bold Centered Text',
        alignment: 'center',
        style: 'bold',
        fontSize: 32,
      );
      expect(result, true);
    });
    
    test('printQRCode', () async {
      // Test with default size
      var result = await s600Plugin.printQRCode(
        data: 'https://example.com',
      );
      expect(result, true);
      
      // Test with custom size
      result = await s600Plugin.printQRCode(
        data: 'https://example.com',
        size: 300,
      );
      expect(result, true);
    });
    
    test('printBarcode', () async {
      // Test with default parameters
      var result = await s600Plugin.printBarcode(
        data: '123456789012',
      );
      expect(result, true);
      
      // Test with custom parameters
      result = await s600Plugin.printBarcode(
        data: '123456789012',
        type: 'code39',
        height: 120,
      );
      expect(result, true);
    });
    
    test('feedPaper', () async {
      final result = await s600Plugin.feedPaper(3);
      expect(result, true);
    });
    
    test('setPrintDensity', () async {
      final result = await s600Plugin.setPrintDensity(8);
      expect(result, true);
    });
    
    // New test for printRawBytes
    test('printRawBytes', () async {
      // Test with sample ESC/POS commands
      List<int> testBytes = [
        // ESC @ - Initialize printer
        27, 64,
        // ESC ! - Select print mode (0 = normal)
        27, 33, 0,
        // Text "Test"
        84, 101, 115, 116
      ];
      
      final result = await s600Plugin.printRawBytes(testBytes);
      
      // Verify the response model
      expect(result, isA<PrinterResponseModel>());
      expect(result.success, true);
      expect(result.message, 'Print completed successfully');
    });
    
    // Test with custom chunk size and delay
    test('printRawBytes with custom parameters', () async {
      List<int> testBytes = [27, 64, 27, 33, 0, 84, 101, 115, 116];
      
      final result = await s600Plugin.printRawBytes(
        testBytes,
        chunkSize: 100,
        delayMs: 200
      );
      
      expect(result.success, true);
    });
    
    // Test PrinterResponseModel
    test('PrinterResponseModel creation', () {
      final model = PrinterResponseModel(
        success: true,
        message: 'Test message'
      );
      
      expect(model.success, true);
      expect(model.message, 'Test message');
    });
    
    test('PrinterResponseModel from map', () {
      final model = PrinterResponseModel.fromMap({
        'success': true,
        'message': 'Test message'
      });
      
      expect(model.success, true);
      expect(model.message, 'Test message');
    });
    
    test('PrinterResponseModel handles missing fields', () {
      final model = PrinterResponseModel.fromMap({});
      
      expect(model.success, false);
      expect(model.message, 'Unknown response');
    });
  });
}
