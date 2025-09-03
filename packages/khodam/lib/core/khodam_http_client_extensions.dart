import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:khodam/khodam.dart';

extension KhodamHttpClientExtensions on Future<HttpClientRequest> {
  /// Intercept http client with khodam. This extension method provides additional
  /// helpful method to intercept httpClientResponse.
  Future<HttpClientResponse> interceptWithKhodam(Khodam khodam,
      {dynamic body, Map<String, dynamic>? headers}) async {
    HttpClientRequest request = await this;
    if (body != null) {
      request.write(body);
    }
    if (headers != null) {
      headers.forEach(
        (String key, dynamic value) {
          request.headers.add(key, value);
        },
      );
    }
    khodam.onHttpClientRequest(request, body: body);
    var httpResponse = await request.close();
    var responseBody = await utf8.decoder.bind(httpResponse).join();
    khodam.onHttpClientResponse(httpResponse, request, body: responseBody);
    return httpResponse;
  }
}
