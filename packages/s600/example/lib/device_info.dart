import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'logger.dart';

/// Utility class to get and log device information
class DeviceInfoUtil {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static final PrinterLogger _logger = PrinterLogger();

  /// Log detailed information about the device
  static Future<void> logDeviceInfo() async {
    try {
      if (kIsWeb) {
        _logWebDeviceInfo(await _deviceInfoPlugin.webBrowserInfo);
      } else if (Platform.isAndroid) {
        _logAndroidDeviceInfo(await _deviceInfoPlugin.androidInfo);
      } else if (Platform.isIOS) {
        _logIosDeviceInfo(await _deviceInfoPlugin.iosInfo);
      } else if (Platform.isLinux) {
        _logLinuxDeviceInfo(await _deviceInfoPlugin.linuxInfo);
      } else if (Platform.isMacOS) {
        _logMacOSDeviceInfo(await _deviceInfoPlugin.macOsInfo);
      } else if (Platform.isWindows) {
        _logWindowsDeviceInfo(await _deviceInfoPlugin.windowsInfo);
      }
    } catch (e) {
      _logger.error('Failed to get device info', details: e.toString());
    }
  }

  static void _logAndroidDeviceInfo(AndroidDeviceInfo info) {
    _logger.info('Device Info: Android',
      details: '''
Device: ${info.device}
Brand: ${info.brand}
Manufacturer: ${info.manufacturer}
Model: ${info.model}
Android Version: ${info.version.release} (SDK ${info.version.sdkInt})
Hardware: ${info.hardware}
Product: ${info.product}
Board: ${info.board}
Supported ABIs: ${info.supportedAbis.join(', ')}
Physical Device: ${info.isPhysicalDevice}
''');
  }

  static void _logIosDeviceInfo(IosDeviceInfo info) {
    _logger.info('Device Info: iOS',
      details: '''
Name: ${info.name}
Model: ${info.model}
System Name: ${info.systemName}
System Version: ${info.systemVersion}
Identifier: ${info.identifierForVendor}
Physical Device: ${info.isPhysicalDevice}
''');
  }

  static void _logWebDeviceInfo(WebBrowserInfo info) {
    _logger.info('Device Info: Web Browser',
      details: '''
Browser: ${info.browserName}
Platform: ${info.platform}
User Agent: ${info.userAgent}
''');
  }

  static void _logMacOSDeviceInfo(MacOsDeviceInfo info) {
    _logger.info('Device Info: macOS',
      details: '''
Computer Name: ${info.computerName}
Host Name: ${info.hostName}
Arch: ${info.arch}
Model: ${info.model}
Kernel Version: ${info.kernelVersion}
OS Version: ${info.osRelease}
''');
  }

  static void _logWindowsDeviceInfo(WindowsDeviceInfo info) {
    _logger.info('Device Info: Windows',
      details: '''
Computer Name: ${info.computerName}
Number of Cores: ${info.numberOfCores}
System Memory (MB): ${info.systemMemoryInMegabytes}
BuildNumber: ${info.buildNumber}
Version: ${info.majorVersion}.${info.minorVersion}.${info.buildNumber}
''');
  }

  static void _logLinuxDeviceInfo(LinuxDeviceInfo info) {
    _logger.info('Device Info: Linux',
      details: '''
Name: ${info.name}
Version: ${info.version}
ID: ${info.id}
Pretty Name: ${info.prettyName}
''');
  }

  /// Get a summary of device info for display
  static Future<String> getDeviceSummary() async {
    try {
      if (kIsWeb) {
        final info = await _deviceInfoPlugin.webBrowserInfo;
        return '${info.browserName} on ${info.platform}';
      } else if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        return '${info.manufacturer} ${info.model} (Android ${info.version.release})';
      } else if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        return '${info.model} (iOS ${info.systemVersion})';
      } else if (Platform.isLinux) {
        final info = await _deviceInfoPlugin.linuxInfo;
        return '${info.prettyName}';
      } else if (Platform.isMacOS) {
        final info = await _deviceInfoPlugin.macOsInfo;
        return '${info.model} (macOS ${info.osRelease})';
      } else if (Platform.isWindows) {
        final info = await _deviceInfoPlugin.windowsInfo;
        return 'Windows ${info.majorVersion}.${info.minorVersion}';
      }
      return 'Unknown device';
    } catch (e) {
      return 'Device info not available';
    }
  }
} 