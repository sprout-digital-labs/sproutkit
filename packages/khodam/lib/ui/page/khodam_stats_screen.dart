import 'package:flutter/material.dart';
import 'package:khodam/core/khodam_core.dart';
import 'package:khodam/helper/khodam_conversion_helper.dart';
import 'package:khodam/model/khodam_http_call.dart';

class KhodamStatsScreen extends StatelessWidget {
  final KhodamCore khodamCore;

  const KhodamStatsScreen(this.khodamCore);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: khodamCore.brightness,
        primarySwatch: Colors.green,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Khodam - HTTP Inspector - Stats"),
        ),
        body: Container(
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: _buildMainListWidgets(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainListWidgets() {
    return [
      _getRow("Total requests:", "${_getTotalRequests()}"),
      _getRow("Pending requests:", "${_getPendingRequests()}"),
      _getRow("Success requests:", "${_getSuccessRequests()}"),
      _getRow("Redirection requests:", "${_getRedirectionRequests()}"),
      _getRow("Error requests:", "${_getErrorRequests()}"),
      _getRow(
          "Bytes send:", KhodamConversionHelper.formatBytes(_getBytesSent())),
      _getRow("Bytes received:",
          KhodamConversionHelper.formatBytes(_getBytesReceived())),
      _getRow("Average request time:",
          "${KhodamConversionHelper.formatTime(_getAverageRequestTime())}"),
      _getRow("Max request time:",
          "${KhodamConversionHelper.formatTime(_getMaxRequestTime())}"),
      _getRow("Min request time:",
          "${KhodamConversionHelper.formatTime(_getMinRequestTime())}"),
      _getRow("Get requests:", "${_getRequests("GET")} "),
      _getRow("Post requests:", "${_getRequests("POST")} "),
      _getRow("Delete requests:", "${_getRequests("DELETE")} "),
      _getRow("Put requests:", "${_getRequests("PUT")} "),
      _getRow("Patch requests:", "${_getRequests("PATCH")} "),
      _getRow("Secured requests:", "${_getSecuredRequests()}"),
      _getRow("Unsecured requests:", "${_getUnsecuredRequests()}"),
    ];
  }

  Widget _getRow(String label, String value) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: _getLabelTextStyle(),
        ),
        Padding(
          padding: EdgeInsets.only(left: 10),
        ),
        Text(
          value,
          style: _getValueTextStyle(),
        )
      ],
    );
  }

  TextStyle _getLabelTextStyle() {
    return TextStyle(fontSize: 16);
  }

  TextStyle _getValueTextStyle() {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  }

  int _getTotalRequests() {
    return calls.length;
  }

  int _getSuccessRequests() => calls
      .where((call) =>
          call.response != null &&
          call.response!.status >= 200 &&
          call.response!.status < 300)
      .toList()
      .length;

  int _getRedirectionRequests() => calls
      .where((call) =>
          call.response != null &&
          call.response!.status >= 300 &&
          call.response!.status < 400)
      .toList()
      .length;

  int _getErrorRequests() => calls
      .where((call) =>
          call.response != null &&
          call.response!.status >= 400 &&
          call.response!.status < 600)
      .toList()
      .length;

  int _getPendingRequests() =>
      calls.where((call) => call.loading).toList().length;

  int _getBytesSent() {
    int bytes = 0;
    calls.forEach((KhodamHttpCall call) {
      bytes += call.request!.size;
    });
    return bytes;
  }

  int _getBytesReceived() {
    int bytes = 0;
    calls.forEach((KhodamHttpCall call) {
      if (call.response != null) {
        bytes += call.response!.size;
      }
    });
    return bytes;
  }

  int _getAverageRequestTime() {
    int requestTimeSum = 0;
    int requestsWithDurationCount = 0;
    calls.forEach((KhodamHttpCall call) {
      if (call.duration != 0) {
        requestTimeSum = call.duration;
        requestsWithDurationCount++;
      }
    });
    if (requestTimeSum == 0) {
      return 0;
    }
    return requestTimeSum ~/ requestsWithDurationCount;
  }

  int _getMaxRequestTime() {
    int maxRequestTime = 0;
    calls.forEach((KhodamHttpCall call) {
      if (call.duration > maxRequestTime) {
        maxRequestTime = call.duration;
      }
    });
    return maxRequestTime;
  }

  int _getMinRequestTime() {
    int minRequestTime = 10000000;
    if (calls.length == 0) {
      minRequestTime = 0;
    } else {
      calls.forEach((KhodamHttpCall call) {
        if (call.duration != 0 && call.duration < minRequestTime) {
          minRequestTime = call.duration;
        }
      });
    }
    return minRequestTime;
  }

  int _getRequests(String requestType) =>
      calls.where((call) => call.method == requestType).toList().length;

  int _getSecuredRequests() =>
      calls.where((call) => call.secure).toList().length;

  int _getUnsecuredRequests() =>
      calls.where((call) => !call.secure).toList().length;

  List<KhodamHttpCall> get calls => khodamCore.callsSubject.value;
}
