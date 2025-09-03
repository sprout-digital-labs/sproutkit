import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'logger.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({Key? key}) : super(key: key);

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final logger = PrinterLogger();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _autoScroll = true;
  LogLevel _filterLevel = LogLevel.debug;
  String? _searchText;
  String? _selectedSource;
  bool _showExportOptions = false;
  
  @override
  void initState() {
    super.initState();
    logger.addListener(_onLogAdded);
  }
  
  @override
  void dispose() {
    logger.removeListener(_onLogAdded);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _onLogAdded(LogEntry entry) {
    setState(() {});
    if (_autoScroll && _scrollController.hasClients) {
      Future.delayed(Duration.zero, () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _exportLogs(BuildContext context) async {
    if (kIsWeb) {
      _copyLogsToClipboard();
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Text File (.txt)'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('JSON File (.json)'),
              onTap: () => Navigator.pop(context, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy to Clipboard'),
              onTap: () => Navigator.pop(context, 'clipboard'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == null) return;

    String? filePath;
    switch (result) {
      case 'text':
        filePath = await logger.exportLogsToText();
        break;
      case 'json':
        filePath = await logger.exportLogsToJson();
        break;
      case 'clipboard':
        _copyLogsToClipboard();
        return;
    }

    if (filePath != null) {
      // Show success message with option to share
      if (!mounted) return;
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logs Exported'),
          content: Text('Logs exported to:\n$filePath'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Share File'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await Share.shareXFiles([XFile(filePath)]);
      }
    }
  }
  
  void _copyLogsToClipboard() {
    final logs = logger.getFilteredLogs(
      minLevel: _filterLevel,
      searchText: _searchText,
      source: _selectedSource,
    ).map((e) => e.toFormattedString()).join('\n\n');
    
    Clipboard.setData(ClipboardData(text: logs));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blue.shade700;
      case LogLevel.debug:
        return Colors.grey.shade700;
      case LogLevel.warning:
        return Colors.orange.shade700;
      case LogLevel.error:
        return Colors.red.shade700;
    }
  }

  List<String> _getAvailableSources() {
    final sources = <String>{};
    for (final log in logger.getLogs()) {
      if (log.source != null && log.source!.isNotEmpty) {
        sources.add(log.source!);
      }
    }
    return sources.toList()..sort();
  }
  
  @override
  Widget build(BuildContext context) {
    final logs = logger.getFilteredLogs(
      minLevel: _filterLevel,
      searchText: _searchText,
      source: _selectedSource,
    );
    
    final sources = _getAvailableSources();
    
    return Column(
      children: [
        // Header with title, search, and controls
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Printer Logs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  DropdownButton<LogLevel>(
                    value: _filterLevel,
                    isDense: true,
                    underline: Container(),
                    items: LogLevel.values.map((level) {
                      return DropdownMenuItem<LogLevel>(
                        value: level,
                        child: Text(level.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterLevel = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  if (sources.isNotEmpty) ...[
                    DropdownButton<String?>(
                      value: _selectedSource,
                      isDense: true,
                      underline: Container(),
                      hint: const Text('Source'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Sources'),
                        ),
                        ...sources.map((source) {
                          return DropdownMenuItem<String>(
                            value: source,
                            child: Text(source),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSource = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: Icon(
                      _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
                      size: 20,
                    ),
                    tooltip: _autoScroll ? 'Auto-scroll enabled' : 'Auto-scroll disabled',
                    onPressed: () {
                      setState(() {
                        _autoScroll = !_autoScroll;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    tooltip: _searchText != null ? 'Clear search' : 'Search logs',
                    onPressed: () {
                      if (_searchText != null) {
                        setState(() {
                          _searchText = null;
                          _searchController.clear();
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Search Logs'),
                            content: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Enter search term',
                                border: OutlineInputBorder(),
                              ),
                              autofocus: true,
                              onSubmitted: (value) {
                                Navigator.pop(context);
                                setState(() {
                                  _searchText = value.isNotEmpty ? value : null;
                                });
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _searchText = _searchController.text.isNotEmpty 
                                        ? _searchController.text 
                                        : null;
                                  });
                                },
                                child: const Text('Search'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: 'More options',
                    onPressed: () {
                      setState(() {
                        _showExportOptions = !_showExportOptions;
                      });
                    },
                  ),
                ],
              ),
              if (_showExportOptions)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                        onPressed: _copyLogsToClipboard,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (!kIsWeb)
                        TextButton.icon(
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export'),
                          onPressed: () => _exportLogs(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Clear'),
                        onPressed: () {
                          setState(() {
                            logger.clear();
                            _showExportOptions = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_searchText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Text(
                        'Search: "${_searchText}"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _searchText = null;
                            _searchController.clear();
                          });
                        },
                        child: const Icon(Icons.close, size: 14),
                      ),
                      const Spacer(),
                      Text(
                        'Found: ${logs.length} logs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      _searchText != null 
                          ? 'No logs matching "${_searchText}"'
                          : 'No logs yet',
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: index < logs.length - 1
                              ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.formattedTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _getLogColor(log.level).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getLogColor(log.level).withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    log.levelLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getLogColor(log.level),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            if (log.source != null) ...[
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.only(left: 64),
                                child: Text(
                                  'Source: ${log.source}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                            if (log.details != null) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 64),
                                child: Text(
                                  log.details!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
} 