import 'package:khodam/khodam.dart';
import 'package:http/http.dart';

extension KhodamHttpExtensions on Future<Response> {
  /// Intercept http request with khodam. This extension method provides additional
  /// helpful method to intercept https' response.
  Future<Response> interceptWithKhodam(Khodam khodam, {dynamic body}) async {
    Response response = await this;
    khodam.onHttpResponse(response, body: body);
    return response;
  }
}
