import 'package:flutter/material.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/ui/widget/khodam_base_call_details_widget.dart';

class KhodamCallResponseWidget extends StatefulWidget {
  final KhodamHttpCall call;
  final String searchQuery;
  final ValueNotifier<int>? matchesNotifier;

  KhodamCallResponseWidget(this.call, {this.searchQuery = '', this.matchesNotifier});

  @override
  State<StatefulWidget> createState() => _KhodamCallResponseWidget();
}

class _KhodamCallResponseWidget extends KhodamBaseCallDetailsWidgetState<KhodamCallResponseWidget> {
  static const _imageContentType = "image";
  static const _videoContentType = "video";
  static const _jsonContentType = "json";
  static const _xmlContentType = "xml";
  static const _textContentType = "text";

  static const _kLargeOutputSize = 100000;
  bool _showLargeBody = false;
  bool _showUnsupportedBody = false;
  int _matchCount = 0;

  KhodamHttpCall get _call => widget.call;

  @override
  void didUpdateWidget(covariant KhodamCallResponseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTotalMatches();
  }

  void _updateTotalMatches() {
    if (widget.matchesNotifier != null) {
      widget.matchesNotifier!.value += _matchCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matchesNotifier != null) {
      widget.matchesNotifier!.value = 0; // Reset before building
    }
    _matchCount = 0;
    List<Widget> rows = [];
    if (!_call.loading) {
      rows.addAll(_buildGeneralDataRows(_call));
      rows.addAll(_buildHeadersRows(_call));
      rows.addAll(_buildBodyRows(_call));

      _updateTotalMatches();
      return Container(
        padding: const EdgeInsets.all(6),
        child: ListView(children: rows),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SelectableText("Awaiting response...")],
        ),
      );
    }
  }

  @override
  void dispose() {
    //_betterPlayerController?.dispose();
    super.dispose();
  }

  List<Widget> _buildGeneralDataRows(KhodamHttpCall call) {
    List<Widget> rows = [];
    rows.add(getListRow("Received:", _buildHighlightedText(call.response!.time.toString())));
    rows.add(getListRow("Bytes received:", _buildHighlightedText(formatBytes(call.response!.size))));

    var status = call.response!.status;
    var statusText = "$status";
    if (status == -1) {
      statusText = "Error";
    }

    rows.add(getListRow("Status:", _buildHighlightedText(statusText)));
    return rows;
  }

  List<Widget> _buildHeadersRows(KhodamHttpCall call) {
    List<Widget> rows = [];
    var headers = call.response!.headers;
    Widget headersContent = SelectableText("Headers are empty");
    if (headers != null && headers.length > 0) {
      headersContent = SelectableText("");
    }
    rows.add(getListRow("Headers: ", headersContent));
    if (call.response!.headers != null) {
      call.response!.headers!.forEach((header, value) {
        rows.add(getListRow("   • $header:", SelectableText(value.toString())));
      });
    }
    return rows;
  }

  List<Widget> _buildBodyRows(KhodamHttpCall call) {
    List<Widget> rows = [];
    if (_isImageResponse(call)) {
      rows.addAll(_buildImageBodyRows(call));
    } else if (_isVideoResponse(call)) {
      // rows.addAll(_buildVideoBodyRows());
    } else if (_isTextResponse(call)) {
      if (_isLargeResponseBody(call)) {
        rows.addAll(_buildLargeBodyTextRows(call));
      } else {
        rows.addAll(_buildTextBodyRows(call));
      }
    } else {
      rows.addAll(_buildUnknownBodyRows(call));
    }

    return rows;
  }

  List<Widget> _buildImageBodyRows(KhodamHttpCall call) {
    List<Widget> rows = [];
    rows.add(
      Column(
        children: [
          Row(
            children: [
              Text(
                "Body: Image",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(height: 8),
          Image.network(
            call.uri,
            fit: BoxFit.fill,
            headers: _buildRequestHeaders(call),
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    return rows;
  }

  List<Widget> _buildLargeBodyTextRows(KhodamHttpCall call) {
    List<Widget> rows = [];
    if (_showLargeBody) {
      return _buildTextBodyRows(call);
    } else {
      rows.add(getListRow("Body:", Text("Too large to show (${call.response!.body.toString().length} Bytes)")));
      rows.add(const SizedBox(height: 8));
      rows.add(
        ElevatedButton(
          child: const Text("Show body"),
          onPressed: () {
            setState(() {
              _showLargeBody = true;
            });
          },
        ),
      );
      rows.add(const SizedBox(height: 8));
      rows.add(const Text("Warning! It will take some time to render output."));
    }
    return rows;
  }

  List<Widget> _buildTextBodyRows(KhodamHttpCall call) {
    List<Widget> rows = [];
    var headers = call.response!.headers;
    var bodyContent = formatBody(call.response!.body, getContentType(headers))!;
    rows.add(getListRow("Body:", _buildHighlightedText(bodyContent)));
    return rows;
  }

  List<Widget> _buildUnknownBodyRows(KhodamHttpCall call) {
    List<Widget> rows = [];
    var headers = call.response!.headers;
    var contentType = getContentType(headers) ?? "<unknown>";

    if (_showUnsupportedBody) {
      var bodyContent = formatBody(call.response!.body, getContentType(headers))!;
      rows.add(getListRow("Body:", _buildHighlightedText(bodyContent)));
    } else {
      rows.add(getListRow(
          "Body:",
          Text("Unsupported body. Khodam can render video/image/text body. "
              "Response has Content-Type: $contentType which can't be handled. "
              "If you're feeling lucky you can try button below to try render body"
              " as text, but it may fail.")));
      rows.add(
        ElevatedButton(
          child: const Text("Show unsupported body"),
          onPressed: () {
            setState(() {
              _showUnsupportedBody = true;
            });
          },
        ),
      );
    }
    return rows;
  }

  Map<String, String> _buildRequestHeaders(KhodamHttpCall call) {
    Map<String, String> requestHeaders = {};
    if (call.request?.headers != null) {
      requestHeaders.addAll(
        call.request!.headers.map(
          (String key, dynamic value) {
            return MapEntry(key, value.toString());
          },
        ),
      );
    }
    return requestHeaders;
  }

  bool _isImageResponse(KhodamHttpCall call) {
    return _getContentTypeOfResponse(call)!.toLowerCase().contains(_imageContentType);
  }

  bool _isVideoResponse(KhodamHttpCall call) {
    return _getContentTypeOfResponse(call)!.toLowerCase().contains(_videoContentType);
  }

  bool _isTextResponse(KhodamHttpCall call) {
    String responseContentTypeLowerCase = _getContentTypeOfResponse(call)!.toLowerCase();

    return responseContentTypeLowerCase.contains(_jsonContentType) ||
        responseContentTypeLowerCase.contains(_xmlContentType) ||
        responseContentTypeLowerCase.contains(_textContentType);
  }

  String? _getContentTypeOfResponse(KhodamHttpCall call) {
    return getContentType(call.response!.headers);
  }

  bool _isLargeResponseBody(KhodamHttpCall call) {
    return call.response!.body != null && call.response!.body.toString().length > _kLargeOutputSize;
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
}
