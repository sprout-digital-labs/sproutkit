import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logger.dart';
import 'package:s600/s600.dart';
import 'printer_types.dart' as printer;
import 'device_info.dart';

/// A page to display detailed printer and device information
class InfoPage extends StatefulWidget {
  final S600 printerPlugin;
  
  const InfoPage({super.key, required this.printerPlugin});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final _logger = PrinterLogger();
  
  String _platformVersion = 'Unknown';
  String _printerModel = 'S600 Printer';
  String _firmwareVersion = 'Unknown';
  String _serialNumber = 'Unknown';
  String _deviceInfo = 'Loading...';
  Map<String, String> _printerDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInformation();
  }

  /// Load all printer and device information
  Future<void> _loadInformation() async {
    _logger.debug('Loading printer and device information');
    setState(() {
      _isLoading = true;
    });
    
    await Future.wait([
      _getPlatformVersion(),
      _getDeviceInfo(),
      _getPrinterDetails(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }

  /// Get platform version information
  Future<void> _getPlatformVersion() async {
    try {
      final version = await widget.printerPlugin.getPlatformVersion();
      setState(() {
        _platformVersion = version ?? 'Unknown';
      });
      _logger.debug('Platform version retrieved: $_platformVersion');
    } catch (e) {
      _logger.error('Failed to get platform version', details: e.toString());
      setState(() {
        _platformVersion = 'Error retrieving version';
      });
    }
  }

  /// Get device information
  Future<void> _getDeviceInfo() async {
    try {
      final info = await DeviceInfoUtil.getDeviceSummary();
      setState(() {
        _deviceInfo = info;
      });
      _logger.debug('Device info retrieved: $_deviceInfo');
    } catch (e) {
      _logger.error('Failed to get device info', details: e.toString());
      setState(() {
        _deviceInfo = 'Error retrieving device info';
      });
    }
  }

  /// Get printer details
  Future<void> _getPrinterDetails() async {
    try {
      // In a real implementation, this would fetch detailed printer info
      // For now, we'll use mock data as placeholder
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _printerDetails = {
          'Manufacturer': 'Example Corp',
          'Model': 'S600',
          'Communication': 'USB / Bluetooth / Serial',
          'Max Paper Width': '58mm',
          'Resolution': '203 DPI',
          'Print Speed': 'Up to 90mm/s',
          'Character Set': 'ASCII / Unicode',
          'Barcode Support': 'UPC-A, UPC-E, CODE39, CODE128, QR',
          'Paper Sensor': 'Yes',
          'Auto Cutter': 'Yes',
        };
      });
      _logger.debug('Printer details loaded');
    } catch (e) {
      _logger.error('Failed to get printer details', details: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInformation,
            tooltip: 'Refresh information',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'System Information',
                  Icons.computer,
                  Colors.blue,
                  [
                    {'Platform': _platformVersion},
                    {'Device': _deviceInfo},
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  'Printer Information',
                  Icons.print,
                  Colors.green,
                  [
                    {'Model': _printerModel},
                    {'Firmware': _firmwareVersion},
                    {'Serial Number': _serialNumber},
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  'Printer Specifications',
                  Icons.info_outline,
                  Colors.orange,
                  _printerDetails.entries.map((e) => {e.key: e.value}).toList(),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Color color, List<Map<String, String>> details) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (title == 'System Information')
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      final text = details.map((item) => 
                        item.entries.map((e) => '${e.key}: ${e.value}').join('\n')
                      ).join('\n');
                      
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                      _logger.debug('Copied system info to clipboard');
                    },
                    tooltip: 'Copy to clipboard',
                  ),
              ],
            ),
            const Divider(),
            ...details.map((item) => 
              item.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${e.key}:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList()
            ).expand((item) => item).toList(),
          ],
        ),
      ),
    );
  }
} 