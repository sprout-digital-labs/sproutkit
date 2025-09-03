import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

enum LogLevel {
  info,
  debug,
  warning,
  error,
}

class LogEntry {
  final String id;
  final DateTime timestamp;
  final String message;
  final LogLevel level;
  final String? details;
  final String? source;

  LogEntry({
    required this.message,
    required this.level,
    this.details,
    this.source,
  }) : 
    timestamp = DateTime.now(),
    id = _generateId();

  String get formattedTime => 
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';

  String get formattedDate =>
      '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

  String get fullTimestamp => '$formattedDate $formattedTime';

  String get levelLabel {
    switch (level) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': levelLabel,
      'message': message,
      'details': details,
      'source': source,
    };
  }

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.write('[$fullTimestamp] [$levelLabel] $message');
    
    if (source != null) {
      buffer.write(' (source: $source)');
    }
    
    if (details != null) {
      buffer.write('\n    Details: $details');
    }
    
    return buffer.toString();
  }

  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString() + (1000 + (timestamp % 9000)).toString();
    return random;
  }
}

class PrinterLogger {
  static final PrinterLogger _instance = PrinterLogger._internal();
  factory PrinterLogger() => _instance;

  final int _maxLogs;
  final _logs = ListQueue<LogEntry>();
  final List<Function(LogEntry)> _listeners = [];
  LogLevel _minFilterLevel = LogLevel.debug;
  bool _useConsoleLogging = true;

  PrinterLogger._internal() : _maxLogs = 500 {
    if (kDebugMode) {
      info('PrinterLogger initialized', details: 'Max logs: $_maxLogs');
    }
  }

  void addListener(Function(LogEntry) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(LogEntry) listener) {
    _listeners.remove(listener);
  }

  void _notify(LogEntry entry) {
    for (final listener in _listeners) {
      listener(entry);
    }
  }

  void setMinLogLevel(LogLevel level) {
    _minFilterLevel = level;
    debug('Log filter level changed to ${level.toString().split('.').last}');
  }

  LogLevel getMinLogLevel() => _minFilterLevel;

  void setConsoleLogging(bool enabled) {
    _useConsoleLogging = enabled;
    debug('Console logging ${enabled ? 'enabled' : 'disabled'}');
  }

  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? details,
    String? source,
  }) {
    // Skip logs below the minimum filter level
    if (level.index < _minFilterLevel.index) {
      return;
    }

    final entry = LogEntry(
      message: message,
      level: level,
      details: details,
      source: source,
    );
    
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }

    // Print to console for additional visibility during development
    if (_useConsoleLogging) {
      _printToConsole(entry);
    }
    
    // Notify listeners
    _notify(entry);
  }

  void _printToConsole(LogEntry entry) {
    final sourceText = entry.source != null ? ' [${entry.source}]' : '';
    String prefix = '[${entry.formattedTime}] [${entry.levelLabel}]$sourceText';
    print('$prefix ${entry.message}');
    if (entry.details != null) {
      print('$prefix Details: ${entry.details}');
    }
  }

  void debug(String message, {String? details, String? source}) {
    log(message, level: LogLevel.debug, details: details, source: source);
  }

  void info(String message, {String? details, String? source}) {
    log(message, level: LogLevel.info, details: details, source: source);
  }

  void warning(String message, {String? details, String? source}) {
    log(message, level: LogLevel.warning, details: details, source: source);
  }

  void error(String message, {String? details, String? source}) {
    log(message, level: LogLevel.error, details: details, source: source);
  }

  List<LogEntry> getLogs() {
    return List.from(_logs);
  }

  List<LogEntry> getFilteredLogs({LogLevel? minLevel, String? searchText, String? source}) {
    return _logs.where((log) {
      bool matches = true;
      
      if (minLevel != null && log.level.index < minLevel.index) {
        matches = false;
      }
      
      if (matches && searchText != null && searchText.isNotEmpty) {
        final lowercaseSearch = searchText.toLowerCase();
        final messageMatches = log.message.toLowerCase().contains(lowercaseSearch);
        final detailsMatches = log.details?.toLowerCase().contains(lowercaseSearch) ?? false;
        matches = messageMatches || detailsMatches;
      }
      
      if (matches && source != null && source.isNotEmpty) {
        matches = log.source == source;
      }
      
      return matches;
    }).toList();
  }

  void clear() {
    _logs.clear();
    debug('Logs cleared', source: 'logger');
  }

  /// Export logs to a JSON file and return the file path
  Future<String?> exportLogsToJson() async {
    try {
      if (!kIsWeb) {
        final directory = await path_provider.getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().toString().replaceAll(':', '-').replaceAll(' ', '_').split('.').first;
        final fileName = 'printer_logs_$timestamp.json';
        final file = File('${directory.path}/$fileName');
        
        final jsonLogs = jsonEncode(_logs.map((e) => e.toJson()).toList());
        await file.writeAsString(jsonLogs);
        
        debug('Logs exported to ${file.path}', source: 'logger');
        return file.path;
      }
    } catch (e) {
      error('Failed to export logs', details: e.toString(), source: 'logger');
    }
    return null;
  }

  /// Export logs to a text file and return the file path
  Future<String?> exportLogsToText() async {
    try {
      if (!kIsWeb) {
        final directory = await path_provider.getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().toString().replaceAll(':', '-').replaceAll(' ', '_').split('.').first;
        final fileName = 'printer_logs_$timestamp.txt';
        final file = File('${directory.path}/$fileName');
        
        final buffer = StringBuffer();
        for (final log in _logs) {
          buffer.writeln(log.toFormattedString());
          buffer.writeln('-' * 50);
        }
        
        await file.writeAsString(buffer.toString());
        
        debug('Logs exported to ${file.path}', source: 'logger');
        return file.path;
      }
    } catch (e) {
      error('Failed to export logs', details: e.toString(), source: 'logger');
    }
    return null;
  }
} 