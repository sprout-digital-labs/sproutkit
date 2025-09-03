import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
// Import the real plugin implementation instead of the mock
import 'package:s600/s600.dart';
import 'printer_types.dart' as printer;
import 'logger.dart';
import 'log_viewer.dart';
import 'device_info.dart';
import 'info_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _s600Plugin = S600();
  final _logger = PrinterLogger();
  String _statusMessage = 'Initializing...';
  bool _isInitialized = false;
  printer.PrinterStatus _printerStatus = printer.PrinterStatus.unknown;
  bool _showLogs = false;
  String _deviceInfo = 'Loading device info...';
  String _platformVersion = 'Unknown';
  
  @override
  void initState() {
    super.initState();
    _logger.info('App started');
    _loadDeviceInfo();
    _initPrinter();
  }

  // Load device information
  Future<void> _loadDeviceInfo() async {
    try {
      // Log detailed device information
      await DeviceInfoUtil.logDeviceInfo();
      
      // Get a summary for the UI
      final summary = await DeviceInfoUtil.getDeviceSummary();
      setState(() {
        _deviceInfo = summary;
      });
      _logger.info('Device info loaded', details: summary);
    } catch (e) {
      _logger.error('Failed to load device info', details: e.toString());
      setState(() {
        _deviceInfo = 'Device info unavailable';
      });
    }
  }

  // Initialize the printer
  Future<void> _initPrinter() async {
    try {
      _logger.debug('Calling initPrinter()');
      final result = await _s600Plugin.initPrinter();
      setState(() {
        _isInitialized = result;
        _statusMessage = result 
            ? 'Printer initialized successfully'
            : 'Failed to initialize printer';
      });
      _logger.debug('initPrinter() result: $result');
      if (result) {
        await _checkPrinterStatus();
      }
    } on PlatformException catch (e) {
      _logger.error('PlatformException in initPrinter()', details: '${e.code}: ${e.message}');
      setState(() {
        _statusMessage = 'Error initializing printer: ${e.message}';
      });
    } catch (e) {
      _logger.error('Error in initPrinter()', details: e.toString());
      setState(() {
        _statusMessage = 'Error initializing printer: $e';
      });
    }
  }

  // Check printer status
  Future<void> _checkPrinterStatus() async {
    if (!_isInitialized) {
      _logger.warning('Attempted to check status when printer not initialized');
      await _initPrinter();
      return;
    }

    try {
      _logger.debug('Calling getPrinterStatus()');
      final statusString = await _s600Plugin.getPrinterStatus();
      
      // Convert string status to enum
      printer.PrinterStatus status;
      switch (statusString) {
        case 'ready':
          status = printer.PrinterStatus.ready;
          break;
        case 'busy':
          status = printer.PrinterStatus.busy;
          break;
        case 'outOfPaper':
          status = printer.PrinterStatus.outOfPaper;
          break;
        case 'overheated':
          status = printer.PrinterStatus.overheated;
          break;
        case 'error':
          status = printer.PrinterStatus.error;
          break;
        default:
          status = printer.PrinterStatus.unknown;
      }
      
      setState(() {
        _printerStatus = status;
        _statusMessage = 'Printer status: ${_statusText(status)}';
      });
      _logger.debug('getPrinterStatus() result: $statusString');
    } on PlatformException catch (e) {
      _logger.error('PlatformException in getPrinterStatus()', details: '${e.code}: ${e.message}');
      setState(() {
        _statusMessage = 'Error checking printer status: ${e.message}';
      });
    } catch (e) {
      _logger.error('Error in getPrinterStatus()', details: e.toString());
      setState(() {
        _statusMessage = 'Error checking printer status: $e';
      });
    }
  }

  // Print sample text
  Future<void> _printSampleText() async {
    if (!_isInitialized) {
      _logger.warning('Attempted to print text when printer not initialized');
      setState(() {
        _statusMessage = 'Printer not initialized. Please initialize first.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Printing sample text...';
    });

    try {
      _logger.debug('Calling printText()');
      final result = await _s600Plugin.printText(
        text: 'Hello S600 Printer!\nThis is a test print.\n\n',
        alignment: 'center',
        style: 'bold',
        fontSize: 24,
      );
      
      setState(() {
        _statusMessage = result 
            ? 'Sample text printed successfully' 
            : 'Failed to print sample text';
      });
      _logger.debug('printText() result: $result');
      
      await _checkPrinterStatus();
    } on PlatformException catch (e) {
      _logger.error('PlatformException in printText()', details: '${e.code}: ${e.message}');
      setState(() {
        _statusMessage = 'Error printing text: ${e.message}';
      });
    } catch (e) {
      _logger.error('Error in printText()', details: e.toString());
      setState(() {
        _statusMessage = 'Error printing text: $e';
      });
    }
  }

  // Print QR code
  Future<void> _printQRCode() async {
    if (!_isInitialized) {
      _logger.warning('Attempted to print QR code when printer not initialized');
      setState(() {
        _statusMessage = 'Printer not initialized. Please initialize first.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Printing QR code...';
    });

    try {
      _logger.debug('Calling printQRCode()');
      final result = await _s600Plugin.printQRCode(
        data: 'https://flutter.dev',
        size: 200,
      );
      
      setState(() {
        _statusMessage = result 
            ? 'QR code printed successfully' 
            : 'Failed to print QR code';
      });
      _logger.debug('printQRCode() result: $result');
      
      await _checkPrinterStatus();
    } on PlatformException catch (e) {
      _logger.error('PlatformException in printQRCode()', details: '${e.code}: ${e.message}');
      setState(() {
        _statusMessage = 'Error printing QR code: ${e.message}';
      });
    } catch (e) {
      _logger.error('Error in printQRCode()', details: e.toString());
      setState(() {
        _statusMessage = 'Error printing QR code: $e';
      });
    }
  }

  // Print receipt
  Future<void> _printReceipt() async {
    if (!_isInitialized) {
      _logger.warning('Attempted to print receipt when printer not initialized');
      setState(() {
        _statusMessage = 'Printer not initialized. Please initialize first.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Printing receipt...';
    });

    try {
      _logger.debug('Creating receipt items');
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
        printer.TextPrintItem(
          text: 'Item 2                  \$5.50\n',
          alignment: printer.TextAlignment.left,
          style: printer.TextStyle.normal,
          fontSize: 20,
        ),
        printer.TextPrintItem(
          text: 'Item 3                  \$7.25\n',
          alignment: printer.TextAlignment.left,
          style: printer.TextStyle.normal,
          fontSize: 20,
        ),
        printer.TextPrintItem(
          text: '-------------------------\n',
          alignment: printer.TextAlignment.center,
          style: printer.TextStyle.normal,
          fontSize: 20,
        ),
        printer.TextPrintItem(
          text: 'TOTAL                  \$22.75\n\n',
          alignment: printer.TextAlignment.left,
          style: printer.TextStyle.bold,
          fontSize: 24,
        ),
        printer.BarcodePrintItem(
          data: '123456789',
          type: printer.BarcodeType.code128,
          height: 80,
        ),
        printer.FeedLinePrintItem(lines: 3),
      ];

      _logger.debug('Calling printReceipt()');
      final result = await _s600Plugin.printReceipt(items);
      
      setState(() {
        _statusMessage = result 
            ? 'Receipt printed successfully' 
            : 'Failed to print receipt';
      });
      _logger.debug('printReceipt() result: $result');
      
      await _checkPrinterStatus();
    } on PlatformException catch (e) {
      _logger.error('PlatformException in printReceipt()', details: '${e.code}: ${e.message}');
      setState(() {
        _statusMessage = 'Error printing receipt: ${e.message}';
      });
    } catch (e) {
      _logger.error('Error in printReceipt()', details: e.toString());
      setState(() {
        _statusMessage = 'Error printing receipt: $e';
      });
    }
  }

  // Test for printing raw bytes
  Future<void> _testPrintRawBytes() async {
    try {
      // Initialize the printer first
      bool initialized = await _s600Plugin.initPrinter();
      if (!initialized) {
        setState(() {
          _statusMessage = 'Failed to initialize printer';
        });
        return;
      }
      
      // Example ESC/POS commands for printing a test receipt
      // These are standard ESC/POS commands that should work on most thermal printers
      List<int> bytes = [
        // ESC @ - Initialize printer
        27, 64,
        
        // ESC ! - Select print mode (0 = normal)
        27, 33, 0,
        
        // ESC a - Select justification (1 = center)
        27, 97, 1,
        
        // Print centered title
        83, 54, 48, 48, 32, 80, 114, 105, 110, 116, 101, 114, 32, 84, 101, 115, 116, 10, 10, // "S600 Printer Test\n\n"
        
        // ESC a - Select justification (0 = left)
        27, 97, 0,
        
        // Print normal text
        84, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 111, 102, 32, 114, 97, 119, 32, 98, 121, 116, 101, 115, 32, 112, 114, 105, 110, 116, 105, 110, 103, 46, 10, // "This is a test of raw bytes printing.\n"
        
        // ESC ! - Select print mode (8 = bold)
        27, 33, 8,
        
        // Print bold text
        66, 111, 108, 100, 32, 116, 101, 120, 116, 10, // "Bold text\n"
        
        // ESC ! - Select print mode (0 = normal)
        27, 33, 0,
        
        // Print normal text
        78, 111, 114, 109, 97, 108, 32, 116, 101, 120, 116, 10, 10, // "Normal text\n\n"
        
        // ESC a - Select justification (2 = right)
        27, 97, 2,
        
        // Print right-aligned text
        82, 105, 103, 104, 116, 32, 97, 108, 105, 103, 110, 101, 100, 10, 10, // "Right aligned\n\n"
        
        // ESC a - Select justification (1 = center)
        27, 97, 1,
        
        // GS k - Print QR Code (model, size, data length, data)
        // This is a simplified version and may not work on all printers
        29, 107, 4, 3, 8, 84, 101, 115, 116, 32, 81, 82, // QR code for "Test QR"
        
        // Line feeds
        10, 10, 10, 10,
        
        // GS V - Cut paper (partial cut)
        29, 86, 1
      ];
      
      // Print the raw bytes
      final result = await _s600Plugin.printRawBytes(
        bytes,
        chunkSize: 50,  // Use smaller chunks for better reliability
        delayMs: 100,   // Add more delay between chunks
      );
      
      setState(() {
        _statusMessage = 'Print Result: ${result.success ? 'Success' : 'Failed'}\nMessage: ${result.message}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  // Get printer status text
  String _statusText(printer.PrinterStatus status) {
    switch (status) {
      case printer.PrinterStatus.ready:
        return 'Ready';
      case printer.PrinterStatus.busy:
        return 'Busy';
      case printer.PrinterStatus.outOfPaper:
        return 'Out of Paper';
      case printer.PrinterStatus.overheated:
        return 'Overheated';
      case printer.PrinterStatus.error:
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  // Get status color
  Color _statusColor() {
    switch (_printerStatus) {
      case printer.PrinterStatus.ready:
        return Colors.green;
      case printer.PrinterStatus.busy:
        return Colors.orange;
      case printer.PrinterStatus.outOfPaper:
      case printer.PrinterStatus.overheated:
      case printer.PrinterStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('S600 Printer Example'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkPrinterStatus,
              tooltip: 'Check printer status',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InfoPage(printerPlugin: _s600Plugin),
                  ),
                );
                _logger.debug('Navigated to Info Page');
              },
              tooltip: 'Printer Information',
            ),
            IconButton(
              icon: Icon(_showLogs ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showLogs = !_showLogs;
                });
                _logger.debug('Logs view ${_showLogs ? 'shown' : 'hidden'}');
              },
              tooltip: _showLogs ? 'Hide logs' : 'Show logs',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              flex: _showLogs ? 1 : 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Device info panel
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.devices, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Device Information',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_deviceInfo),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Status panel
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: _statusColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: _statusColor()),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(_isInitialized ? Icons.check_circle : Icons.error, 
                                color: _isInitialized ? Colors.green : Colors.red),
                              const SizedBox(width: 8),
                              Text('Initialization: ${_isInitialized ? "Success" : "Failed"}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.print, color: _statusColor()),
                              const SizedBox(width: 8),
                              Text('Printer Status: ${_statusText(_printerStatus)}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_statusMessage),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    ElevatedButton(
                      onPressed: _initPrinter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Initialize Printer'),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ElevatedButton(
                      onPressed: _isInitialized ? _checkPrinterStatus : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Check Printer Status'),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Print Tests:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Print test buttons
                    ElevatedButton(
                      onPressed: _isInitialized ? _printSampleText : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Print Sample Text'),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ElevatedButton(
                      onPressed: _isInitialized ? _printQRCode : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Print QR Code'),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ElevatedButton(
                      onPressed: _isInitialized ? _printReceipt : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Print Sample Receipt'),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ElevatedButton(
                      onPressed: _testPrintRawBytes,
                      child: const Text('Test Print Raw Bytes'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Log viewer section (conditionally shown)
            if (_showLogs)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const LogViewer(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
