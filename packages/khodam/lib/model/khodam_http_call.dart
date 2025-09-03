import 'package:khodam/model/khodam_http_error.dart';
import 'package:khodam/model/khodam_http_request.dart';
import 'package:khodam/model/khodam_http_response.dart';

class KhodamHttpCall {
  final int id;
  String client = "";
  bool loading = true;
  bool secure = false;
  String method = "";
  String endpoint = "";
  String server = "";
  String uri = "";
  int duration = 0;

  KhodamHttpRequest? request;
  KhodamHttpResponse? response;
  KhodamHttpError? error;

  KhodamHttpCall(this.id) {
    loading = true;
  }

  setResponse(KhodamHttpResponse response) {
    this.response = response;
    loading = false;
  }

  String getCurlCommand() {
    var compressed = false;
    var curlCmd = "curl";
    curlCmd += " -X " + method;
    var headers = request!.headers;
    headers.forEach((key, value) {
      if ("Accept-Encoding" == key && "gzip" == value) {
        compressed = true;
      }
      curlCmd += " -H \'$key: $value\'";
    });

    String? requestBody = request?.body.toString();
    if (requestBody != null && requestBody != '') {
      // try to keep to a single line and use a subshell to preserve any line breaks
      curlCmd += " --data \$'" + requestBody.replaceAll("\n", "\\n") + "'";
    }
    curlCmd += ((compressed) ? " --compressed " : " ") +
        "\'${secure ? 'https://' : 'http://'}$server$endpoint\'";
    return curlCmd;
  }
}
