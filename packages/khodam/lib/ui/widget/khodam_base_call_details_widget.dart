import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:khodam/helper/khodam_conversion_helper.dart';
import 'package:khodam/ui/utils/khodam_parser.dart';

abstract class KhodamBaseCallDetailsWidgetState<T extends StatefulWidget> extends State<T> {
  final JsonEncoder encoder = new JsonEncoder.withIndent('  ');

  Widget getListRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: value,
          ),
        ],
      ),
    );
  }

  SelectableText formatBytesSelectable(int bytes) => SelectableText(KhodamConversionHelper.formatBytes(bytes));

  SelectableText formatDurationSelectable(int duration) => SelectableText(KhodamConversionHelper.formatTime(duration));

  Widget formatBodySelectable(dynamic body, String? contentType) {
    final formattedBody = KhodamParser.formatBody(body, contentType);
    return SelectableText(formattedBody ?? '');
  }

  String formatBytes(int bytes) => KhodamConversionHelper.formatBytes(bytes);

  String formatDuration(int duration) => KhodamConversionHelper.formatTime(duration);

  String? formatBody(dynamic body, String? contentType) => KhodamParser.formatBody(body, contentType);

  String? getContentType(Map<String, dynamic>? headers) => KhodamParser.getContentType(headers);
}
