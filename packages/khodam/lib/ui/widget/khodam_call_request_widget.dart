import 'package:flutter/material.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/ui/widget/khodam_base_call_details_widget.dart';

class KhodamCallRequestWidget extends StatefulWidget {
  final KhodamHttpCall call;
  final String searchQuery;
  final ValueNotifier<int>? matchesNotifier;

  KhodamCallRequestWidget(this.call, {this.searchQuery = '', this.matchesNotifier});

  @override
  State<StatefulWidget> createState() => _KhodamCallRequestWidget();
}

class _KhodamCallRequestWidget extends KhodamBaseCallDetailsWidgetState<KhodamCallRequestWidget> {
  KhodamHttpCall get _call => widget.call;
  int _matchCount = 0;

  @override
  void didUpdateWidget(covariant KhodamCallRequestWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTotalMatches();
  }

  void _updateTotalMatches() {
    if (widget.matchesNotifier != null) {
      widget.matchesNotifier!.value += _matchCount;
    }
  }

  Widget _buildHighlightedText(String text) {
    if (widget.searchQuery.isEmpty) {
      _matchCount = 0;
      return SelectableText(text);
    }

    final matches = RegExp(widget.searchQuery, caseSensitive: false).allMatches(text).toList();
    _matchCount = matches.length;

    if (matches.isEmpty) {
      return SelectableText(text);
    }

    final spans = <TextSpan>[];
    int previousEnd = 0;

    for (final match in matches) {
      if (match.start > previousEnd) {
        spans.add(TextSpan(
          text: text.substring(previousEnd, match.start),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));

      previousEnd = match.end;
    }

    if (previousEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(previousEnd),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matchesNotifier != null) {
      widget.matchesNotifier!.value = 0; // Reset before building
    }
    _matchCount = 0;
    List<Widget> rows = [];
    rows.add(getListRow("Started:", _buildHighlightedText(_call.request!.time.toString())));
    rows.add(getListRow("Bytes sent:", _buildHighlightedText(formatBytes(_call.request!.size))));
    rows.add(getListRow("Content type:", _buildHighlightedText(getContentType(_call.request!.headers)!)));

    var body = _call.request!.body;
    Widget bodyContent = Text("Body is empty");
    if (body != null) {
      bodyContent = _buildHighlightedText(formatBody(body, getContentType(_call.request!.headers))!);
    }
    rows.add(getListRow("Body:", bodyContent));

    var formDataFields = _call.request!.formDataFields;
    if (formDataFields?.isNotEmpty == true) {
      rows.add(getListRow("Form data fields: ", Text("")));
      formDataFields!.forEach((field) {
        rows.add(getListRow("   • ${field.name}:", Text("${field.value}")));
      });
    }

    var formDataFiles = _call.request!.formDataFiles;
    if (formDataFiles?.isNotEmpty == true) {
      rows.add(getListRow("Form data files: ", Text("")));
      formDataFiles!.forEach((field) {
        rows.add(getListRow("   • ${field.fileName}:", Text("${field.contentType} / ${field.length} B")));
      });
    }

    var headers = _call.request!.headers;
    Widget headersContent = Text("Headers are empty");
    if (headers.length > 0) {
      headersContent = Text("");
    }
    rows.add(getListRow("Headers: ", headersContent));
    if (_call.request?.headers != null) {
      _call.request!.headers.forEach((header, value) {
        rows.add(getListRow("   • $header:", Text(value.toString())));
      });
    }

    var queryParameters = _call.request!.queryParameters;
    Widget queryParametersContent = Text("Query parameters are empty");
    if (queryParameters.length > 0) {
      queryParametersContent = Text("");
    }
    rows.add(getListRow("Query Parameters: ", queryParametersContent));
    if (_call.request?.queryParameters != null) {
      _call.request!.queryParameters.forEach((query, value) {
        rows.add(getListRow("   • $query:", Text(value.toString())));
      });
    }

    _updateTotalMatches();
    return Container(
      padding: const EdgeInsets.all(6),
      child: ListView(children: rows),
    );
  }
}
