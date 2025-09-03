import 'package:flutter/material.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/ui/widget/khodam_base_call_details_widget.dart';

class KhodamCallErrorWidget extends StatefulWidget {
  final KhodamHttpCall call;

  KhodamCallErrorWidget(this.call);

  @override
  State<StatefulWidget> createState() {
    return _KhodamCallErrorWidgetState();
  }
}

class _KhodamCallErrorWidgetState extends KhodamBaseCallDetailsWidgetState<KhodamCallErrorWidget> {
  KhodamHttpCall get _call => widget.call;

  @override
  Widget build(BuildContext context) {
    if (_call.error != null) {
      List<Widget> rows = [];
      var error = _call.error!.error;
      Widget errorText = Text("Error is empty");
      if (error != null) {
        errorText = Text(error.toString());
      }
      rows.add(getListRow("Error:", errorText));

      return Container(
        padding: EdgeInsets.all(6),
        child: ListView(children: rows),
      );
    } else {
      return Center(child: Text("Nothing to display here"));
    }
  }
}
