import 'package:flutter/material.dart';
import 'package:khodam/helper/khodam_conversion_helper.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/model/khodam_http_response.dart';
import 'package:khodam/ui/utils/khodam_constants.dart';

class KhodamCallListItemWidget extends StatelessWidget {
  final KhodamHttpCall call;
  final Function itemClickAction;

  const KhodamCallListItemWidget(this.call, this.itemClickAction);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => itemClickAction(call),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMethodAndEndpointRow(context),
                      const SizedBox(height: 4),
                      _buildServerRow(),
                      const SizedBox(height: 4),
                      _buildStatsRow()
                    ],
                  ),
                ),
                _buildResponseColumn(context)
              ],
            ),
          ),
          _buildDivider()
        ],
      ),
    );
  }

  Widget _buildMethodAndEndpointRow(BuildContext context) {
    Color? textColor = _getEndpointTextColor(context);
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          call.method,
          style: TextStyle(fontSize: 16, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Padding(padding: EdgeInsets.only(left: 10)),
        Expanded(
          child: Text(
            call.endpoint,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: TextStyle(fontSize: 16, color: textColor),
            maxLines: 1,
          ),
        )
      ],
    );
  }

  Widget _buildServerRow() {
    return Row(children: [
      _getSecuredConnectionIcon(call.secure),
      Expanded(
        child: Text(
          call.server,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 14,
          ),
        ),
      ),
    ]);
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
            flex: 1,
            child: Text(_formatTime(call.request!.time),
                style: TextStyle(fontSize: 12))),
        Flexible(
            flex: 1,
            child: Text("${KhodamConversionHelper.formatTime(call.duration)}",
                style: TextStyle(fontSize: 12))),
        Flexible(
          flex: 1,
          child: Text(
            "${KhodamConversionHelper.formatBytes(call.request!.size)} / "
            "${KhodamConversionHelper.formatBytes(call.response!.size)}",
            style: TextStyle(fontSize: 12),
          ),
        )
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: KhodamConstants.grey);
  }

  String _formatTime(DateTime time) {
    return "${formatTimeUnit(time.hour)}:"
        "${formatTimeUnit(time.minute)}:"
        "${formatTimeUnit(time.second)}:"
        "${formatTimeUnit(time.millisecond)}";
  }

  String formatTimeUnit(int timeUnit) {
    return (timeUnit < 10) ? "0$timeUnit" : "$timeUnit";
  }

  Widget _buildResponseColumn(BuildContext context) {
    List<Widget> widgets = [];
    if (call.loading) {
      widgets.add(Text('Loading..', style: TextStyle(fontSize: 12)));
      widgets.add(const SizedBox(height: 4));
    }
    widgets.add(
      Text(
        _getStatus(call.response!),
        style: TextStyle(
          fontSize: 16,
          color: _getStatusTextColor(context),
        ),
      ),
    );
    return Container(
      width: 50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widgets,
      ),
    );
  }

  Color? _getStatusTextColor(BuildContext context) {
    int status = call.response?.status ?? 0;
    if (status == -1) {
      return KhodamConstants.red;
    } else if (status < 200) {
      return Theme.of(context).textTheme.bodyLarge!.color;
    } else if (status >= 200 && status < 300) {
      return KhodamConstants.green;
    } else if (status >= 300 && status < 400) {
      return KhodamConstants.orange;
    } else if (status >= 400 && status < 600) {
      return KhodamConstants.red;
    } else {
      return Theme.of(context).textTheme.bodyLarge!.color;
    }
  }

  Color? _getEndpointTextColor(BuildContext context) {
    if (call.loading) {
      return KhodamConstants.grey;
    } else {
      return _getStatusTextColor(context);
    }
  }

  String _getStatus(KhodamHttpResponse response) {
    if (response.status == -1) {
      return "ERR";
    } else if (response.status == 0) {
      return "???";
    } else {
      return "${response.status}";
    }
  }

  Widget _getSecuredConnectionIcon(bool secure) {
    IconData iconData;
    Color iconColor;
    if (secure) {
      iconData = Icons.lock_outline;
      iconColor = KhodamConstants.green;
    } else {
      iconData = Icons.lock_open;
      iconColor = KhodamConstants.red;
    }
    return Padding(
      padding: EdgeInsets.only(right: 3),
      child: Icon(
        iconData,
        color: iconColor,
        size: 12,
      ),
    );
  }
}
