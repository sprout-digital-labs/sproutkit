import 'dart:async';
import 'dart:math' as math;

import 'printer_types.dart' as printer;
import 'logger.dart';

// Mock implementation of the S600 printer plugin for testing
class S600 {
  bool _isInitialized = false;
  printer.PrinterStatus _status = printer.PrinterStatus.unknown;
  final math.Random _random = math.Random();
  final PrinterLogger _logger = PrinterLogger();
  
  // Timer to automatically reset printer status
  Timer? _statusResetTimer;
  bool _forceReady = false; // Force ready status for debugging

  // Get platform version
  Future<String?> getPlatformVersion() async {
    _logger.info('Getting platform version');
    return 'Mock Android Platform';
  }

  // Initialize the printer
  Future<bool> initPrinter() async {
    _logger.info('Initializing printer...');
    
    // Simulate async initialization
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Always succeed for testing purposes
    _isInitialized = true;
    _status = printer.PrinterStatus.ready;
    _forceReady = true; // Force ready status for testing
    _logger.info('Printer initialized successfully');
    
    return _isInitialized;
  }

  // Get printer status
  Future<printer.PrinterStatus> getPrinterStatus() async {
    _logger.info('Checking printer status...');
    
    // Simulate async status check
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!_isInitialized) {
      _logger.warning('Printer not initialized, returning unknown status');
      return printer.PrinterStatus.unknown;
    }

    // For testing purposes, force ready status to ensure printing works
    if (_forceReady) {
      _status = printer.PrinterStatus.ready;
    }
    
    _logger.info('Printer status: ${_status.toString().split('.').last}');
    return _status;
  }

  // Set up status reset timer
  void _scheduleStatusReset(Duration delay) {
    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(delay, () {
      _status = printer.PrinterStatus.ready;
      _logger.debug('Printer status automatically reset to ready');
    });
  }

  // Print text
  Future<bool> printText({
    required String text,
    printer.TextAlignment alignment = printer.TextAlignment.left,
    printer.TextStyle style = printer.TextStyle.normal,
    int fontSize = 24,
  }) async {
    _logger.info('Printing text...', 
      details: 'Text: "$text", Alignment: ${alignment.toString().split('.').last}, '
        'Style: ${style.toString().split('.').last}, FontSize: $fontSize');
    
    if (!_isInitialized) {
      _logger.error('Failed to print text: printer not initialized');
      return false;
    }
    
    // Set status to busy immediately
    _status = printer.PrinterStatus.busy;
    _logger.debug('Printer status changed to busy');
    
    // Simulate printing - shorter delay for testing
    final printDuration = Duration(milliseconds: 500);
    _logger.debug('Estimated print time: ${printDuration.inMilliseconds}ms');
    await Future.delayed(printDuration);
    
    // Always succeed for testing
    _logger.info('Text printed successfully');
    
    // Set status directly to ready to ensure it doesn't get stuck
    _status = printer.PrinterStatus.ready;
    _logger.debug('Print job completed, printer ready');
    
    return true;
  }

  // Print QR code
  Future<bool> printQRCode({
    required String data,
    int size = 200,
  }) async {
    _logger.info('Printing QR code...', 
      details: 'Data: "$data", Size: $size');
    
    if (!_isInitialized) {
      _logger.error('Failed to print QR code: printer not initialized');
      return false;
    }
    
    // Set status to busy immediately
    _status = printer.PrinterStatus.busy;
    _logger.debug('Printer status changed to busy');
    
    // Simulate printing QR code - shorter delay for testing
    final printDuration = Duration(milliseconds: 500);
    _logger.debug('Estimated print time: ${printDuration.inMilliseconds}ms');
    await Future.delayed(printDuration);
    
    // Always succeed for testing
    _logger.info('QR code printed successfully');
    
    // Set status directly to ready to ensure it doesn't get stuck
    _status = printer.PrinterStatus.ready;
    _logger.debug('Print job completed, printer ready');
    
    return true;
  }

  // Print barcode
  Future<bool> printBarcode({
    required String data,
    printer.BarcodeType type = printer.BarcodeType.code128,
    int height = 100,
  }) async {
    _logger.info('Printing barcode...',
      details: 'Data: "$data", Type: ${type.toString().split('.').last}, Height: $height');
    
    if (!_isInitialized) {
      _logger.error('Failed to print barcode: printer not initialized');
      return false;
    }
    
    // Set status to busy immediately
    _status = printer.PrinterStatus.busy;
    _logger.debug('Printer status changed to busy');
    
    // Simulate printing barcode - shorter delay for testing
    final printDuration = Duration(milliseconds: 500);
    _logger.debug('Estimated print time: ${printDuration.inMilliseconds}ms');
    await Future.delayed(printDuration);
    
    // Always succeed for testing
    _logger.info('Barcode printed successfully');
    
    // Set status directly to ready to ensure it doesn't get stuck
    _status = printer.PrinterStatus.ready;
    _logger.debug('Print job completed, printer ready');
    
    return true;
  }

  // Print receipt
  Future<bool> printReceipt(List<printer.PrintItem> items) async {
    _logger.info('Printing receipt...',
      details: 'Items count: ${items.length}');
    
    if (!_isInitialized) {
      _logger.error('Failed to print receipt: printer not initialized');
      return false;
    }
    
    // Set status to busy immediately
    _status = printer.PrinterStatus.busy;
    _logger.debug('Printer status changed to busy');
    
    // Log each item type
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is printer.TextPrintItem) {
        _logger.debug('Receipt item $i: Text', 
          details: 'Text: "${item.text.trim()}", '
            'Alignment: ${item.alignment.toString().split('.').last}, '
            'Style: ${item.style.toString().split('.').last}');
      } else if (item is printer.BarcodePrintItem) {
        _logger.debug('Receipt item $i: Barcode', 
          details: 'Data: "${item.data}", '
            'Type: ${item.type.toString().split('.').last}');
      } else if (item is printer.FeedLinePrintItem) {
        _logger.debug('Receipt item $i: Feed Line', 
          details: 'Lines: ${item.lines}');
      } else {
        _logger.debug('Receipt item $i: ${item.runtimeType}');
      }
    }
    
    // Simulate printing a receipt - shorter delay for testing
    final printDuration = Duration(milliseconds: 500);
    _logger.debug('Estimated print time: ${printDuration.inMilliseconds}ms');
    await Future.delayed(printDuration);
    
    // Always succeed for testing
    _logger.info('Receipt printed successfully');
    
    // Set status directly to ready to ensure it doesn't get stuck
    _status = printer.PrinterStatus.ready;
    _logger.debug('Print job completed, printer ready');
    
    return true;
  }

  // Set print density
  Future<bool> setPrintDensity(int density) async {
    _logger.info('Setting print density...', 
      details: 'Density: $density');
    
    if (!_isInitialized) {
      _logger.error('Failed to set print density: printer not initialized');
      return false;
    }
    
    // Simulate setting print density
    await Future.delayed(const Duration(milliseconds: 300));
    
    _logger.info('Print density set successfully');
    return true;
  }

  // Feed paper
  Future<bool> feedPaper(int lines) async {
    _logger.info('Feeding paper...', 
      details: 'Lines: $lines');
    
    if (!_isInitialized) {
      _logger.error('Failed to feed paper: printer not initialized');
      return false;
    }
    
    // Simulate paper feeding
    await Future.delayed(Duration(milliseconds: 200));
    
    // Always succeed for testing
    _logger.info('Paper fed successfully');
    
    return true;
  }
} 