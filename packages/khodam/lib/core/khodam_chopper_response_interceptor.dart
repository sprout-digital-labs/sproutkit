import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/model/khodam_http_request.dart';
import 'package:khodam/model/khodam_http_response.dart';
import 'package:http/http.dart';

import 'khodam_core.dart';

class KhodamChopperInterceptor
    implements chopper.ResponseInterceptor, chopper.RequestInterceptor {
  /// KhodamCore instance
  final KhodamCore khodamCore;

  /// Creates instance of chopper interceptor
  KhodamChopperInterceptor(this.khodamCore);

  /// Creates hashcode based on request
  int getRequestHashCode(BaseRequest baseRequest) {
    int hashCodeSum = 0;
    hashCodeSum += baseRequest.url.hashCode;
    hashCodeSum += baseRequest.method.hashCode;
    if (baseRequest.headers.isNotEmpty) {
      baseRequest.headers.forEach((key, value) {
        hashCodeSum += key.hashCode;
        hashCodeSum += value.hashCode;
      });
    }
    if (baseRequest.contentLength != null) {
      hashCodeSum += baseRequest.contentLength.hashCode;
    }

    return hashCodeSum.hashCode;
  }

  /// Handles chopper request and creates khodam http call
  @override
  FutureOr<chopper.Request> onRequest(chopper.Request request) async {
    var baseRequest = await request.toBaseRequest();
    KhodamHttpCall call = KhodamHttpCall(getRequestHashCode(baseRequest));
    String endpoint = "";
    String server = "";
    if (request.baseUri.path.isEmpty) {
      List<String> split = request.url.path.split("/");
      if (split.length > 2) {
        server = split[1] + split[2];
      }
      if (split.length > 4) {
        endpoint = "/";
        for (int splitIndex = 3; splitIndex < split.length; splitIndex++) {
          endpoint += split[splitIndex] + "/";
        }
        endpoint = endpoint.substring(0, endpoint.length - 1);
      }
    } else {
      endpoint = request.url.path;
      server = request.baseUri.path;
    }

    call.method = request.method;
    call.endpoint = endpoint;
    call.server = server;
    call.client = "Chopper";
    if (request.baseUri.path.contains("https") ||
        request.uri.path.contains("https")) {
      call.secure = true;
    }

    KhodamHttpRequest khodamHttpRequest = KhodamHttpRequest();

    if (request.body == null) {
      khodamHttpRequest.size = 0;
      khodamHttpRequest.body = "";
    } else {
      khodamHttpRequest.size = utf8.encode(request.body).length;
      khodamHttpRequest.body = request.body;
    }
    khodamHttpRequest.time = DateTime.now();
    khodamHttpRequest.headers = request.headers;

    String? contentType = "unknown";
    if (request.headers.containsKey("Content-Type")) {
      contentType = request.headers["Content-Type"];
    }
    khodamHttpRequest.contentType = contentType;
    khodamHttpRequest.queryParameters = request.parameters;

    call.request = khodamHttpRequest;
    call.response = KhodamHttpResponse();

    khodamCore.addCall(call);
    return request;
  }

  /// Handles chopper response and adds data to existing khodam http call
  FutureOr<chopper.Response> onResponse(chopper.Response response) {
    var httpResponse = KhodamHttpResponse();
    httpResponse.status = response.statusCode;
    if (response.body == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.body;
      httpResponse.size = utf8.encode(response.body.toString()).length;
    }

    httpResponse.time = DateTime.now();
    Map<String, String> headers = Map();
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    khodamCore.addResponse(
        httpResponse, getRequestHashCode(response.base.request!));
    return response;
  }
}
