# S600 Printer Plugin

A Flutter plugin for integrating with S600 thermal printers. This plugin provides a simple and effective way to perform various printing operations using the official S600 KTP SDK.

## Features

- Printer initialization and status checking
- Text printing with customizable alignment, style, and font size
- QR code printing with adjustable size
- Barcode printing with customizable type and height
- Receipt printing with multiple item types
- Raw bytes printing for direct ESC/POS commands
- Paper feeding and print density control

## Requirements

- Android: minSdk 21+
- KTP SDK (included in the plugin)
- Device with S600 compatible hardware

## Installation

### From pub.dev

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  s600: ^1.0.0
```

Run:
```bash
flutter pub get
```

### From Git Repository

You can also import the package directly from a Git repository:

```yaml
dependencies:
  s600:
    git:
      url: git@github.com:scvcashenable/cashkit.git
      ref: s600_v0.0.1
      path: packages/s600
```

This is useful when you need a specific version or branch of the package.

## Android Setup

The plugin requires specific permissions to function properly. These are included automatically when the plugin is added to your app, but you may need to request runtime permissions for Android 6.0+ (API level 23+).

### Required Permissions:
- `android.permission.INTERNET`
- `android.permission.READ_PHONE_STATE`
- `android.permission.WRITE_EXTERNAL_STORAGE`

## Usage

### Importing

```dart
import 'package:s600/s600.dart';
```

### Initialize the plugin

```dart
final s600Plugin = S600();
```

### Initialize Printer

Before using any printing functionality, you must initialize the printer:

```dart
try {
  final result = await s600Plugin.initPrinter();
  if (result) {
    print('Printer initialized successfully');
  } else {
    print('Failed to initialize printer');
  }
} catch (e) {
  print('Error initializing printer: $e');
}
```

### Check Printer Status

You can check the printer's status before performing any print operations:

```dart
try {
  final status = await s600Plugin.getPrinterStatus();
  print('Printer status: $status');
  
  // Status can be one of:
  // "ready" - Printer is ready to print
  // "busy" - Printer is currently printing
  // "outOfPaper" - Printer is out of paper
  // "overheated" - Printer is overheated
  // "error" - General error state
  // "unknown" - Status cannot be determined
} catch (e) {
  print('Error checking printer status: $e');
}
```

### Print Text

```dart
try {
  final result = await s600Plugin.printText(
    text: 'Hello S600 Printer!',
    alignment: 'center', // 'left', 'center', or 'right'
    style: 'bold',      // 'normal' or 'bold'
    fontSize: 24,       // font size in points
  );
  
  if (result) {
    print('Text printed successfully');
  } else {
    print('Failed to print text');
  }
} catch (e) {
  print('Error printing text: $e');
}
```

### Print QR Code

```dart
try {
  final result = await s600Plugin.printQRCode(
    data: 'https://flutter.dev',
    size: 200, // Size in pixels
  );
  
  if (result) {
    print('QR code printed successfully');
  } else {
    print('Failed to print QR code');
  }
} catch (e) {
  print('Error printing QR code: $e');
}
```

### Print Barcode

```dart
try {
  final result = await s600Plugin.printBarcode(
    data: '123456789012',
    type: 'code128',  // 'upc-a', 'upc-e', 'ean13', 'ean8', 'code39', 'itf', 'codabar', or 'code128'
    height: 100,      // Height in pixels
  );
  
  if (result) {
    print('Barcode printed successfully');
  } else {
    print('Failed to print barcode');
  }
} catch (e) {
  print('Error printing barcode: $e');
}
```

### Print Raw Bytes (ESC/POS Commands)

For direct control over the printer, you can send raw bytes using ESC/POS commands:

```dart
try {
  // ESC/POS commands for printing "Hello World" centered and bold
  List<int> bytes = [
    // ESC @ - Initialize printer
    27, 64,
    // ESC ! - Select print mode (8 = bold)
    27, 33, 8,
    // ESC a - Select justification (1 = center)
    27, 97, 1,
    // Text to print
    72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33,
    // Line feed
    10, 10, 10,
    // Paper cut
    29, 86, 1
  ];
  
  final response = await s600Plugin.printRawBytes(
    bytes,
    chunkSize: 50,  // Optional: Size of chunks to break data into
    delayMs: 50,    // Optional: Delay between chunks in milliseconds
  );
  
  if (response.success) {
    print('Raw bytes printed successfully: ${response.message}');
  } else {
    print('Failed to print raw bytes: ${response.message}');
  }
} catch (e) {
  print('Error printing raw bytes: $e');
}
```

The `printRawBytes` method provides:
- Direct access to printer capabilities through ESC/POS commands
- Chunking for reliable printing of large data
- Configurable parameters for optimization
- Structured response with success status and message

### Print Receipt

For more complex printing, you can use the receipt printing functionality with multiple item types:

```dart
import 'package:s600/printer_types.dart' as printer;

try {
  final items = [
    printer.TextPrintItem(
      text: '===== SAMPLE RECEIPT =====\n',
      alignment: printer.TextAlignment.center,
      style: printer.TextStyle.bold,
      fontSize: 24,
    ),
    printer.TextPrintItem(
      text: 'Date: ${DateTime.now().toString().substring(0, 19)}\n',
      alignment: printer.TextAlignment.left,
      style: printer.TextStyle.normal,
      fontSize: 20,
    ),
    printer.TextPrintItem(
      text: 'Item 1                 \$10.00\n',
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

  final result = await s600Plugin.printReceipt(items);
  
  if (result) {
    print('Receipt printed successfully');
  } else {
    print('Failed to print receipt');
  }
} catch (e) {
  print('Error printing receipt: $e');
}
```

### Feed Paper

```dart
try {
  final result = await s600Plugin.feedPaper(lines: 3);
  
  if (result) {
    print('Paper fed successfully');
  } else {
    print('Failed to feed paper');
  }
} catch (e) {
  print('Error feeding paper: $e');
}
```

### Set Print Density

```dart
try {
  final result = await s600Plugin.setPrintDensity(density: 8); // 0-8 scale
  
  if (result) {
    print('Print density set successfully');
  } else {
    print('Failed to set print density');
  }
} catch (e) {
  print('Error setting print density: $e');
}
```

## Implementation Details

This plugin uses the official KTP SDK for S600 printers, providing a reliable and robust integration. It communicates with the printer through a service-based architecture rather than direct Bluetooth connection, which improves stability and reliability.

## Troubleshooting

### Printer Not Found
- Ensure the S600 printer service is installed on the device
- Check if the service package (`com.kp.ktsdkservice`) is accessible
- Verify all required permissions are granted

### Printer Not Responding
- Check the printer status using `getPrinterStatus()`
- If the status is "busy", wait for the current operation to complete
- If the status is "error", try reinitializing the printer with `initPrinter()`

### Out of Paper
- The printer will return status "outOfPaper" if it's out of paper
- Load new paper and check the status again

### Blank Output When Using Raw Bytes
- Ensure you're using the correct ESC/POS commands for your printer model
- Try using the ISO-8859-1 encoding for text commands
- Use smaller chunk sizes and longer delays for more reliable printing
- Check the printer's documentation for supported commands

## License

This plugin is available under the MIT License.

