import 'dart:convert';
import 'dart:io';

import 'package:khodam/core/khodam_core.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/model/khodam_http_request.dart';
import 'package:khodam/model/khodam_http_response.dart';

class KhodamHttpClientAdapter {
  /// KhodamCore instance
  final KhodamCore khodamCore;

  /// Creates khodam http client adapter
  KhodamHttpClientAdapter(this.khodamCore);

  /// Handles httpClientRequest and creates http khodam call from it
  void onRequest(HttpClientRequest request, {dynamic body}) {
    KhodamHttpCall call = KhodamHttpCall(request.hashCode);
    call.loading = true;
    call.client = "HttpClient (io package)";
    call.method = request.method;
    call.uri = request.uri.toString();

    var path = request.uri.path;
    if (path.length == 0) {
      path = "/";
    }

    call.endpoint = path;
    call.server = request.uri.host;
    if (request.uri.scheme == "https") {
      call.secure = true;
    }
    KhodamHttpRequest httpRequest = KhodamHttpRequest();
    if (body == null) {
      httpRequest.size = 0;
      httpRequest.body = "";
    } else {
      httpRequest.size = utf8.encode(body.toString()).length;
      httpRequest.body = body;
    }
    httpRequest.time = DateTime.now();
    Map<String, dynamic> headers = Map();
    httpRequest.headers.forEach((header, value) {
      headers[header] = value;
    });

    httpRequest.headers = headers;
    String? contentType = "unknown";
    if (headers.containsKey("Content-Type")) {
      contentType = headers["Content-Type"];
    }

    httpRequest.contentType = contentType;
    httpRequest.cookies = request.cookies;

    call.request = httpRequest;
    call.response = KhodamHttpResponse();
    khodamCore.addCall(call);
  }

  /// Handles httpClientRequest and adds response to http khodam call
  void onResponse(HttpClientResponse response, HttpClientRequest request,
      {dynamic body}) async {
    KhodamHttpResponse httpResponse = KhodamHttpResponse();
    httpResponse.status = response.statusCode;

    if (body != null) {
      httpResponse.body = body;
      httpResponse.size = utf8.encode(body.toString()).length;
    } else {
      httpResponse.body = "";
      httpResponse.size = 0;
    }
    httpResponse.time = DateTime.now();
    Map<String, String> headers = Map();
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;
    khodamCore.addResponse(httpResponse, request.hashCode);
  }
}
