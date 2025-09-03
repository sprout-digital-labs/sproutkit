import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khodam/core/khodam_core.dart';
import 'package:khodam/helper/khodam_alert_helper.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/model/khodam_menu_item.dart';
import 'package:khodam/ui/page/khodam_call_details_screen.dart';
import 'package:khodam/ui/page/khodam_routes_list_screen.dart';
import 'package:khodam/ui/utils/khodam_constants.dart';
import 'package:khodam/ui/widget/khodam_call_list_item_widget.dart';

import 'khodam_stats_screen.dart';

class KhodamCallsListScreen extends StatefulWidget {
  final KhodamCore _khodamCore;

  KhodamCallsListScreen(this._khodamCore);

  @override
  _KhodamCallsListScreenState createState() => _KhodamCallsListScreenState();
}

class _KhodamCallsListScreenState extends State<KhodamCallsListScreen> {
  KhodamCore get khodamCore => widget._khodamCore;
  bool _searchEnabled = false;
  final TextEditingController _queryTextEditingController = TextEditingController();
  List<KhodamMenuItem> _menuItems = [];

  _KhodamCallsListScreenState() {
    _menuItems.add(KhodamMenuItem("Delete", Icons.delete));
    _menuItems.add(KhodamMenuItem("Routes", Icons.history_edu_outlined));
    _menuItems.add(KhodamMenuItem("Stats", Icons.insert_chart));
    _menuItems.add(KhodamMenuItem("Save", Icons.save));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: widget._khodamCore.brightness,
        primarySwatch: Colors.green,
      ),
      child: Scaffold(
        floatingActionButton: StreamBuilder<List<KhodamHttpCall>>(
          stream: khodamCore.callsSubject,
          builder: (context, snapshot) {
            List<KhodamHttpCall> calls = snapshot.data ?? [];
            String query = _queryTextEditingController.text.trim();
            if (query.isNotEmpty) {
              calls = calls.where((call) => call.endpoint.toLowerCase().contains(query.toLowerCase())).toList();
            }
            if (calls.isNotEmpty) {
              return FloatingActionButton(
                backgroundColor: KhodamConstants.lightRed,
                key: Key('share_key'),
                onPressed: () async {
                  // Share.share(await _getSharableResponseString(),
                  //     subject: 'Request Details');
                  await Clipboard.setData(
                    ClipboardData(
                      text: calls
                          .map((call) => '${call.response?.status ?? '?'} | ${call.method} | ${call.endpoint}')
                          .join('\n\n'), // Adds a newline between each call
                    ),
                  );
                },
                child: Icon(Icons.share),
              );
            } else {
              return Icon(Icons.share);
            }
          },
        ),
        appBar: AppBar(
          title: _searchEnabled ? _buildSearchField() : _buildTitleWidget(),
          actions: [
            _buildSearchButton(),
            _buildMenuButton(),
          ],
        ),
        body: _buildCallsListWrapper(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _queryTextEditingController.dispose();
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: Icon(Icons.search),
      onPressed: _onSearchClicked,
    );
  }

  void _onSearchClicked() {
    setState(() {
      _searchEnabled = !_searchEnabled;
      if (!_searchEnabled) {
        _queryTextEditingController.text = "";
      }
    });
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<KhodamMenuItem>(
      onSelected: (KhodamMenuItem item) => _onMenuItemSelected(item),
      itemBuilder: (BuildContext context) {
        return _menuItems.map((KhodamMenuItem item) {
          return PopupMenuItem<KhodamMenuItem>(
            value: item,
            child: Row(children: [
              Icon(
                item.iconData,
                color: KhodamConstants.lightRed,
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
              ),
              Text(item.title)
            ]),
          );
        }).toList();
      },
    );
  }

  Widget _buildTitleWidget() {
    return Text("Khodam - Labamu API's Inspector");
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _queryTextEditingController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search keywords...",
        hintStyle: TextStyle(
          fontSize: 16.0,
          color: Colors.white,
        ),
        // border: InputBorder,
      ),
      style: TextStyle(fontSize: 16.0),
      onChanged: _updateSearchQuery,
    );
  }

  void _onMenuItemSelected(KhodamMenuItem menuItem) {
    if (menuItem.title == "Delete") {
      _showRemoveDialog();
    }
    if (menuItem.title == "Stats") {
      _showStatsScreen();
    }
    if (menuItem.title == "Routes") {
      _showRouteScreen();
    }
  }

  Widget _buildCallsListWrapper() {
    return StreamBuilder<List<KhodamHttpCall>>(
      stream: khodamCore.callsSubject,
      builder: (context, snapshot) {
        List<KhodamHttpCall> calls = snapshot.data ?? [];
        String query = _queryTextEditingController.text.trim();
        if (query.isNotEmpty) {
          calls = calls.where((call) => call.endpoint.toLowerCase().contains(query.toLowerCase())).toList();
        }
        if (calls.isNotEmpty) {
          return _buildCallsListWidget(calls);
        } else {
          return _buildEmptyWidget();
        }
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            Icons.error_outline,
            color: KhodamConstants.orange,
          ),
          const SizedBox(height: 6),
          Text(
            "There are no calls to show",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "• Check if you send any http request",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              "• Check your Khodam configuration",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              "• Check search filters",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            )
          ])
        ]),
      ),
    );
  }

  Widget _buildCallsListWidget(List<KhodamHttpCall> calls) {
    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        return KhodamCallListItemWidget(calls[index], _onListItemClicked);
      },
    );
  }

  void _onListItemClicked(KhodamHttpCall call) {
    Navigator.push(
      widget._khodamCore.getContext()!,
      MaterialPageRoute(
        builder: (context) => KhodamCallDetailsScreen(call, widget._khodamCore),
      ),
    );
  }

  void _showRemoveDialog() {
    KhodamAlertHelper.showAlert(
      context,
      "Delete calls",
      "Do you want to delete http calls?",
      firstButtonTitle: "No",
      firstButtonAction: () => {},
      secondButtonTitle: "Yes",
      secondButtonAction: () => _removeCalls(),
    );
  }

  void _removeCalls() {
    khodamCore.removeCalls();
  }

  void _showStatsScreen() {
    Navigator.push(
      khodamCore.getContext()!,
      MaterialPageRoute(
        builder: (context) => KhodamStatsScreen(widget._khodamCore),
      ),
    );
  }

  void _showRouteScreen() {
    Navigator.push(
      khodamCore.getContext()!,
      MaterialPageRoute(
        builder: (context) => KhodamRoutesScreen(widget._khodamCore),
      ),
    );
  }

  void _updateSearchQuery(String query) {
    setState(() {});
  }
}
