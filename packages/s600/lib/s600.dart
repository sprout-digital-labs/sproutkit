import 's600_platform_interface.dart';

/// A response model for printer operations
class PrinterResponseModel {
  final bool success;
  final String message;

  PrinterResponseModel({required this.success, required this.message});

  factory PrinterResponseModel.fromMap(Map<String, dynamic> map) {
    return PrinterResponseModel(
      success: map['success'] ?? false,
      message: map['message'] ?? 'Unknown response',
    );
  }
}

class S600 {
  Future<String?> getPlatformVersion() {
    return S600Platform.instance.getPlatformVersion();
  }
  
  /// Initialize the printer
  Future<bool> initPrinter() {
    return S600Platform.instance.initPrinter();
  }
  
  /// Get printer status
  Future<String> getPrinterStatus() {
    return S600Platform.instance.getPrinterStatus();
  }
  
  /// Print text
  Future<bool> printText({
    required String text,
    String alignment = 'left',
    String style = 'normal',
    int fontSize = 24,
  }) {
    return S600Platform.instance.printText(
      text,
      alignment: alignment,
      style: style,
      fontSize: fontSize,
    );
  }
  
  /// Print QR code
  Future<bool> printQRCode({
    required String data,
    int size = 200,
  }) {
    return S600Platform.instance.printQRCode(
      data,
      size: size,
    );
  }
  
  /// Print barcode
  Future<bool> printBarcode({
    required String data,
    String type = 'code128',
    int height = 100,
  }) {
    return S600Platform.instance.printBarcode(
      data,
      type: type,
      height: height,
    );
  }
  
  /// Print raw bytes directly to the printer
  /// 
  /// [bytes] - List of integers (bytes) to send to the printer
  /// [chunkSize] - Size of chunks to break the data into (default: 50)
  /// [delayMs] - Delay between chunks in milliseconds (default: 50)
  Future<PrinterResponseModel> printRawBytes(
    List<int> bytes, {
    int chunkSize = 50,
    int delayMs = 50,
  }) async {
    try {
      final response = await S600Platform.instance.printRawBytes(
        bytes,
        chunkSize: chunkSize,
        delayMs: delayMs,
      );
      
      if (response is Map) {
        return PrinterResponseModel.fromMap(Map<String, dynamic>.from(response));
      }
      
      // Handle if response is just a boolean for backward compatibility
      if (response is bool) {
        return PrinterResponseModel(
          success: response,
          message: response ? 'Print completed successfully' : 'Print failed',
        );
      }
      
      return PrinterResponseModel(success: false, message: 'Unknown response type');
    } catch (e) {
      return PrinterResponseModel(success: false, message: e.toString());
    }
  }
  
  /// Feed paper
  Future<bool> feedPaper(int lines) {
    return S600Platform.instance.feedPaper(lines);
  }
  
  /// Set print density
  Future<bool> setPrintDensity(int density) {
    return S600Platform.instance.setPrintDensity(density);
  }
  
  /// Print receipt - implementation for compatibility with example app
  /// This method will print each item in the receipt sequentially
  Future<bool> printReceipt(List<dynamic> items) async {
    bool success = true;
    
    // Process each item in the receipt
    for (var item in items) {
      bool itemSuccess = true;
      
      if (item.runtimeType.toString().contains('TextPrintItem')) {
        // Print text item
        itemSuccess = await printText(
          text: item.text,
          alignment: _convertAlignment(item.alignment.toString()),
          style: _convertStyle(item.style.toString()),
          fontSize: item.fontSize,
        );
      } else if (item.runtimeType.toString().contains('BarcodePrintItem')) {
        // Print barcode item
        itemSuccess = await printBarcode(
          data: item.data,
          type: _convertBarcodeType(item.type.toString()),
          height: item.height,
        );
      } else if (item.runtimeType.toString().contains('FeedLinePrintItem')) {
        // Feed paper
        itemSuccess = await feedPaper(item.lines);
      }
      
      // If any item fails, mark the whole receipt as failed
      if (!itemSuccess) {
        success = false;
      }
    }
    
    return success;
  }
  
  // Helper methods to convert enum values to strings
  String _convertAlignment(String alignmentEnum) {
    if (alignmentEnum.contains('center')) return 'center';
    if (alignmentEnum.contains('right')) return 'right';
    return 'left';
  }
  
  String _convertStyle(String styleEnum) {
    if (styleEnum.contains('bold')) return 'bold';
    return 'normal';
  }
  
  String _convertBarcodeType(String typeEnum) {
    if (typeEnum.contains('code39')) return 'code39';
    if (typeEnum.contains('qrCode')) return 'qrcode';
    return 'code128';
  }
}
