import 'package:flutter/material.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/ui/widget/khodam_base_call_details_widget.dart';

class KhodamCallOverviewWidget extends StatefulWidget {
  final KhodamHttpCall call;

  KhodamCallOverviewWidget(this.call);

  @override
  State<StatefulWidget> createState() {
    return _KhodamCallOverviewWidget();
  }
}

class _KhodamCallOverviewWidget extends KhodamBaseCallDetailsWidgetState<KhodamCallOverviewWidget> {
  KhodamHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = [];
    rows.add(getListRow("Method: ", SelectableText(_call.method)));
    rows.add(getListRow("Server: ", SelectableText(_call.server)));
    rows.add(getListRow("Endpoint: ", SelectableText(_call.endpoint)));
    rows.add(getListRow("Started:", SelectableText(_call.request!.time.toString())));
    rows.add(getListRow("Finished:", SelectableText(_call.response!.time.toString())));
    rows.add(getListRow("Duration:", SelectableText(formatDuration(_call.duration))));
    rows.add(getListRow("Bytes sent:", SelectableText(formatBytes(_call.request!.size))));
    rows.add(getListRow("Bytes received:", SelectableText(formatBytes(_call.response!.size))));
    rows.add(getListRow("Client:", SelectableText(_call.client)));
    rows.add(getListRow("Secure:", SelectableText(_call.secure.toString())));
    return Container(
      padding: const EdgeInsets.all(6),
      child: ListView(children: rows),
    );
  }
}
