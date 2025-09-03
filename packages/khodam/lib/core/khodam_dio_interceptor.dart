import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:khodam/core/khodam_core.dart';
import 'package:khodam/model/khodam_form_data_file.dart';
import 'package:khodam/model/khodam_from_data_field.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/model/khodam_http_error.dart';
import 'package:khodam/model/khodam_http_request.dart';
import 'package:khodam/model/khodam_http_response.dart';

class KhodamDioInterceptor extends InterceptorsWrapper {
  /// KhodamCore instance
  final KhodamCore khodamCore;

  /// Creates dio interceptor
  KhodamDioInterceptor(this.khodamCore);

  /// Handles dio request and creates khodam http call based on it
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    KhodamHttpCall call = new KhodamHttpCall(options.hashCode);

    Uri uri = options.uri;
    call.method = options.method;
    var path = options.uri.path;
    if (path.length == 0) {
      path = "/";
    }
    call.endpoint = path;
    call.server = uri.host;
    call.client = "Dio";
    call.uri = options.uri.toString();

    if (uri.scheme == "https") {
      call.secure = true;
    }

    KhodamHttpRequest request = KhodamHttpRequest();

    var data = options.data;
    if (data == null) {
      request.size = 0;
      request.body = "";
    } else {
      if (data is FormData) {
        request.body += "Form data";

        if (data.fields.isNotEmpty == true) {
          List<KhodamFormDataField> fields = [];
          data.fields.forEach((entry) {
            fields.add(KhodamFormDataField(entry.key, entry.value));
          });
          request.formDataFields = fields;
        }
        if (data.files.isNotEmpty == true) {
          List<KhodamFormDataFile> files = [];
          data.files.forEach((entry) {
            files
                .add(KhodamFormDataFile(entry.value.filename!, entry.value.contentType.toString(), entry.value.length));
          });

          request.formDataFiles = files;
        }
      } else {
        request.size = utf8.encode(data.toString()).length;
        request.body = data;
      }
    }

    request.time = DateTime.now();
    request.headers = options.headers;
    request.contentType = options.contentType.toString();
    request.queryParameters = options.queryParameters;

    call.request = request;
    call.response = KhodamHttpResponse();

    khodamCore.addCall(call);
    handler.next(options);
  }

  /// Handles dio response and adds data to khodam http call
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    var httpResponse = KhodamHttpResponse();
    httpResponse.status = response.statusCode!;

    if (response.data == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.data;
      httpResponse.size = utf8.encode(response.data.toString()).length;
    }

    httpResponse.time = DateTime.now();
    Map<String, String> headers = Map();
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    khodamCore.addResponse(httpResponse, response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to khodam http call
  @override
  void onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) {
    var httpError = KhodamHttpError();
    httpError.error = error.toString();
    if (error is Error) {
      var basicError = error as Error;
      httpError.stackTrace = basicError.stackTrace;
    }

    khodamCore.addError(httpError, error.requestOptions.hashCode);
    var httpResponse = KhodamHttpResponse();
    httpResponse.time = DateTime.now();
    if (error.response == null) {
      httpResponse.status = -1;
      khodamCore.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      if (error.response != null && error.response!.statusCode != null) {
        httpResponse.status = error.response!.statusCode!;
      } else {
        httpResponse.status = 0; // Assign default error status code
      }

      if (error.response!.data == null) {
        httpResponse.body = "";
        httpResponse.size = 0;
      } else {
        httpResponse.body = error.response!.data;
        httpResponse.size = utf8.encode(error.response!.data.toString()).length;
      }
      Map<String, String> headers = Map();
      if (error.response?.headers != null) {
        error.response!.headers.forEach((header, values) {
          headers[header] = values.toString();
        });
      }
      httpResponse.headers = headers;
      khodamCore.addResponse(httpResponse, error.response!.requestOptions.hashCode);
    }
    handler.next(error);
  }
}
