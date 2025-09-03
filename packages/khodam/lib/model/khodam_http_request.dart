import 'dart:io';

import 'package:khodam/model/khodam_form_data_file.dart';
import 'package:khodam/model/khodam_from_data_field.dart';

class KhodamHttpRequest {
  int size = 0;
  DateTime time = DateTime.now();
  Map<String, dynamic> headers = Map();
  dynamic body = "";
  String? contentType = "";
  List<Cookie> cookies = [];
  Map<String, dynamic> queryParameters = Map();
  List<KhodamFormDataFile>? formDataFiles;
  List<KhodamFormDataField>? formDataFields;
}
