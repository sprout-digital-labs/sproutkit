import 'dart:convert';

import 'package:khodam/helper/khodam_conversion_helper.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/ui/utils/khodam_parser.dart';

class KhodamSaveHelper {
  static JsonEncoder _encoder = new JsonEncoder.withIndent('  ');

  static Future<String> _buildKhodamLog() async {
    StringBuffer stringBuffer = StringBuffer();
    stringBuffer.write("Khodam - HTTP Inspector\n");
    stringBuffer.write("Generated: " + DateTime.now().toIso8601String() + "\n");
    stringBuffer.write("\n");
    return stringBuffer.toString();
  }

  static String _buildCallLog(KhodamHttpCall call) {
    StringBuffer stringBuffer = StringBuffer();
    stringBuffer.write("===========================================\n");
    stringBuffer.write("Id: ${call.id}\n");
    stringBuffer.write("============================================\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("General data\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Server: ${call.server} \n");
    stringBuffer.write("Method: ${call.method} \n");
    stringBuffer.write("Endpoint: ${call.endpoint} \n");
    stringBuffer.write("Client: ${call.client} \n");
    stringBuffer.write("Duration ${KhodamConversionHelper.formatTime(call.duration)}\n");
    stringBuffer.write("Secured connection: ${call.secure}\n");
    stringBuffer.write("Completed: ${!call.loading} \n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Request\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Request time: ${call.request!.time}\n");
    stringBuffer.write("Request content type: ${call.request!.contentType}\n");
    stringBuffer.write("Request cookies: ${_encoder.convert(call.request!.cookies)}\n");
    stringBuffer.write("Request parameters: ${_encoder.convert(call.request!.queryParameters)}\n");
    stringBuffer.write("Request headers: ${_encoder.convert(call.request!.headers)}\n");
    stringBuffer.write("Request size: ${KhodamConversionHelper.formatBytes(call.request!.size)}\n");
    stringBuffer.write(
        "Request body: ${KhodamParser.formatBody(call.request!.body, KhodamParser.getContentType(call.request!.headers))}\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Response\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Response time: ${call.response!.time}\n");
    stringBuffer.write("Response status: ${call.response!.status}\n");
    stringBuffer.write("Response size: ${KhodamConversionHelper.formatBytes(call.response!.size)}\n");
    stringBuffer.write("Response headers: ${_encoder.convert(call.response!.headers)}\n");
    stringBuffer.write(
        "Response body: ${KhodamParser.formatBody(call.response!.body, KhodamParser.getContentType(call.response!.headers))}\n");
    if (call.error != null) {
      stringBuffer.write("--------------------------------------------\n");
      stringBuffer.write("Error\n");
      stringBuffer.write("--------------------------------------------\n");
      stringBuffer.write("Error: ${call.error!.error}\n");
      if (call.error!.stackTrace != null) {
        stringBuffer.write("Error stacktrace: ${call.error!.stackTrace}\n");
      }
    }
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("Curl\n");
    stringBuffer.write("--------------------------------------------\n");
    stringBuffer.write("${call.getCurlCommand()}");
    stringBuffer.write("\n");
    stringBuffer.write("==============================================\n");
    stringBuffer.write("\n");

    return stringBuffer.toString();
  }

  static Future<String> buildCallLog(KhodamHttpCall call) async {
    try {
      return await _buildKhodamLog() + _buildCallLog(call);
    } catch (exception) {
      return "Failed to generate call log";
    }
  }
}
