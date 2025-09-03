// Enum for printer status
enum PrinterStatus {
  unknown,
  ready,
  busy,
  outOfPaper,
  overheated,
  error,
}

// Enum for text alignment
enum TextAlignment {
  left,
  center,
  right,
}

// Enum for text style
enum TextStyle {
  normal,
  bold,
  italic,
  boldItalic,
}

// Enum for barcode type
enum BarcodeType {
  code128,
  code39,
  qrCode,
  dataMatrix,
}

// Abstract base class for receipt items
abstract class PrintItem {}

class TextPrintItem extends PrintItem {
  final String text;
  final TextAlignment alignment;
  final TextStyle style;
  final int fontSize;
  
  TextPrintItem({
    required this.text,
    this.alignment = TextAlignment.left,
    this.style = TextStyle.normal,
    this.fontSize = 24,
  });
}

class ImagePrintItem extends PrintItem {
  final List<int> imageData;
  final int? width;
  final int? height;
  
  ImagePrintItem({
    required this.imageData,
    this.width,
    this.height,
  });
}

class BarcodePrintItem extends PrintItem {
  final String data;
  final BarcodeType type;
  final int height;
  
  BarcodePrintItem({
    required this.data,
    this.type = BarcodeType.code128,
    this.height = 100,
  });
}

class FeedLinePrintItem extends PrintItem {
  final int lines;
  
  FeedLinePrintItem({this.lines = 1});
} 