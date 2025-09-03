import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 's600_method_channel.dart';

abstract class S600Platform extends PlatformInterface {
  /// Constructs a S600Platform.
  S600Platform() : super(token: _token);

  static final Object _token = Object();

  static S600Platform _instance = MethodChannelS600();

  /// The default instance of [S600Platform] to use.
  ///
  /// Defaults to [MethodChannelS600].
  static S600Platform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [S600Platform] when
  /// they register themselves.
  static set instance(S600Platform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  
  /// Initialize the printer
  Future<bool> initPrinter() {
    throw UnimplementedError('initPrinter() has not been implemented.');
  }
  
  /// Get printer status
  Future<String> getPrinterStatus() {
    throw UnimplementedError('getPrinterStatus() has not been implemented.');
  }
  
  /// Print text
  Future<bool> printText(String text, {String alignment = 'left', String style = 'normal', int fontSize = 24}) {
    throw UnimplementedError('printText() has not been implemented.');
  }
  
  /// Print QR code
  Future<bool> printQRCode(String data, {int size = 200}) {
    throw UnimplementedError('printQRCode() has not been implemented.');
  }
  
  /// Print barcode
  Future<bool> printBarcode(String data, {String type = 'code128', int height = 100}) {
    throw UnimplementedError('printBarcode() has not been implemented.');
  }
  
  /// Print raw bytes
  Future<dynamic> printRawBytes(
    List<int> bytes, {
    int chunkSize = 50,
    int delayMs = 50,
  }) {
    throw UnimplementedError('printRawBytes() has not been implemented.');
  }
  
  /// Feed paper
  Future<bool> feedPaper(int lines) {
    throw UnimplementedError('feedPaper() has not been implemented.');
  }
  
  /// Set print density
  Future<bool> setPrintDensity(int density) {
    throw UnimplementedError('setPrintDensity() has not been implemented.');
  }
}
