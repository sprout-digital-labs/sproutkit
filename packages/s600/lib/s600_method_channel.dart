import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 's600_platform_interface.dart';

/// An implementation of [S600Platform] that uses method channels.
class MethodChannelS600 extends S600Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('s600');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
  
  @override
  Future<bool> initPrinter() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('initPrinter');
      return result ?? false;
    } catch (e) {
      debugPrint('S600 init printer error: $e');
      return false;
    }
  }
  
  @override
  Future<String> getPrinterStatus() async {
    try {
      final status = await methodChannel.invokeMethod<String>('getPrinterStatus');
      return status ?? 'unknown';
    } catch (e) {
      debugPrint('S600 get printer status error: $e');
      return 'error';
    }
  }
  
  @override
  Future<bool> printText(String text, {String alignment = 'left', String style = 'normal', int fontSize = 24}) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('printText', {
        'text': text,
        'alignment': alignment,
        'style': style,
        'fontSize': fontSize,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('S600 print text error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> printQRCode(String data, {int size = 200}) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('printQRCode', {
        'data': data,
        'size': size,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('S600 print QR code error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> printBarcode(String data, {String type = 'code128', int height = 100}) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('printBarcode', {
        'data': data,
        'type': type,
        'height': height,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('S600 print barcode error: $e');
      return false;
    }
  }
  
  @override
  Future<dynamic> printRawBytes(List<int> bytes, {int chunkSize = 50, int delayMs = 50}) async {
    return await methodChannel.invokeMethod('printRawBytes', {
      'bytes': bytes,
      'chunkSize': chunkSize,
      'delayMs': delayMs,
    });
  }
  
  @override
  Future<bool> feedPaper(int lines) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('feedPaper', {
        'lines': lines,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('S600 feed paper error: $e');
      return false;
    }
  }
  
  @override
  Future<bool> setPrintDensity(int density) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('setPrintDensity', {
        'density': density,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('S600 set print density error: $e');
      return false;
    }
  }
}
